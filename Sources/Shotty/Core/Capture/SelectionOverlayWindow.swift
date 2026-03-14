import AppKit
import CoreGraphics

@MainActor
final class SelectionOverlayWindow {
    enum Result {
        case cancelled
        case selected(CGRect)
        case failed(String)
    }

    private var session: Session?

    var isPresentingSelectionUI: Bool {
        session != nil
    }

    func beginSelection(completion: @escaping (Result) -> Void) {
        cancel()

        let screens = NSScreen.screens
        guard screens.isEmpty == false else {
            completion(.failed("No active displays were available for capture."))
            return
        }

        let session = Session(screens: screens) { [weak self] result in
            self?.session = nil
            completion(result)
        }

        self.session = session

        session.present()
    }

    func cancel() {
        session?.finish(with: .cancelled)
    }
}

@MainActor
private final class Session {
    private enum Constants {
        static let minimumSelectionSize: CGFloat = 12
    }

    private struct DragState {
        let startPoint: CGPoint
        var currentPoint: CGPoint

        var selectionRect: CGRect {
            CGRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            ).integral.insetBy(dx: 0, dy: 0)
        }
    }

    private let completion: (SelectionOverlayWindow.Result) -> Void
    private let screens: [NSScreen]
    private var windows: [OverlayPanel] = []
    private var keyMonitor: Any?
    private var dragState: DragState?
    private var hasPushedCursor = false
    private var isFinishing = false

    init(
        screens: [NSScreen],
        completion: @escaping (SelectionOverlayWindow.Result) -> Void
    ) {
        self.screens = screens
        self.completion = completion
    }

    var isDragging: Bool {
        dragState != nil
    }

    var currentSelection: CGRect? {
        dragState?.selectionRect
    }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        pushCursorIfNeeded()

        windows = screens.map { screen in
            OverlayPanel(screen: screen, session: self)
        }

        let keyWindow = windows.first(where: { $0.screenFrame.contains(NSEvent.mouseLocation) }) ?? windows.first

        for window in windows where window !== keyWindow {
            window.orderFrontRegardless()
        }

        keyWindow?.makeKeyAndOrderFront(nil)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            self?.finish(with: .cancelled)
            return nil
        }
    }

    func beginDrag(at point: CGPoint) {
        dragState = DragState(startPoint: point, currentPoint: point)
        refresh()
    }

    func updateDrag(to point: CGPoint) {
        guard var dragState else { return }
        dragState.currentPoint = point
        self.dragState = dragState
        refresh()
    }

    func finishDrag(at point: CGPoint) {
        guard var dragState else { return }
        dragState.currentPoint = point
        self.dragState = dragState

        let selection = dragState.selectionRect
        guard selection.width >= Constants.minimumSelectionSize, selection.height >= Constants.minimumSelectionSize else {
            finish(with: .failed("Selection was too small. Drag a larger region to capture."))
            return
        }

        finish(with: .selected(selection))
    }

    func finish(with result: SelectionOverlayWindow.Result) {
        guard isFinishing == false else { return }
        isFinishing = true

        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }

        for window in windows {
            window.orderOut(nil)
            window.close()
        }

        windows.removeAll()
        popCursorIfNeeded()
        dragState = nil
        completion(result)
    }

    func selectionRect(in screenFrame: CGRect) -> CGRect? {
        guard let selection = currentSelection else { return nil }
        let localRect = selection.intersection(screenFrame)
        guard localRect.isNull == false, localRect.isEmpty == false else { return nil }
        return localRect.offsetBy(dx: -screenFrame.minX, dy: -screenFrame.minY)
    }

    func currentPoint(in screenFrame: CGRect) -> CGPoint? {
        guard let point = dragState?.currentPoint else { return nil }
        let insetFrame = screenFrame.insetBy(dx: 0.5, dy: 0.5)
        guard insetFrame.contains(point) else { return nil }
        return CGPoint(x: point.x - screenFrame.minX, y: point.y - screenFrame.minY)
    }

    func dimensionsText() -> String? {
        guard let selection = currentSelection else { return nil }
        return "\(Int(selection.width.rounded())) × \(Int(selection.height.rounded()))"
    }

    private func refresh() {
        for window in windows {
            window.overlayView.needsDisplay = true
        }
    }

    private func pushCursorIfNeeded() {
        guard hasPushedCursor == false else { return }
        NSCursor.crosshair.push()
        hasPushedCursor = true
    }

    private func popCursorIfNeeded() {
        guard hasPushedCursor else { return }
        NSCursor.pop()
        hasPushedCursor = false
    }
}

private final class OverlayPanel: NSPanel {
    let screenFrame: CGRect
    let overlayView: OverlayView

    init(screen: NSScreen, session: Session) {
        screenFrame = screen.frame
        overlayView = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size), session: session, screenFrame: screen.frame)

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        isFloatingPanel = true
        level = NSWindow.Level(Int(CGShieldingWindowLevel()))
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        animationBehavior = .none
        isMovable = false
        contentView = overlayView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        overlayView.cancelSelection()
    }
}

private final class OverlayView: NSView {
    private enum Palette {
        static let dim = NSColor.black.withAlphaComponent(0.36)
        static let selectionFill = NSColor.white.withAlphaComponent(0.06)
        static let selectionStroke = NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.33, alpha: 0.96)
        static let selectionGlow = NSColor(calibratedRed: 0.42, green: 0.16, blue: 0.85, alpha: 0.42)
        static let reticle = NSColor.white.withAlphaComponent(0.22)
        static let hudFill = NSColor(calibratedWhite: 0.08, alpha: 0.88)
        static let hudStroke = NSColor.white.withAlphaComponent(0.14)
        static let hudText = NSColor.white.withAlphaComponent(0.96)
    }

    private let session: Session
    private let screenFrame: CGRect

    init(frame frameRect: NSRect, session: Session, screenFrame: CGRect) {
        self.session = session
        self.screenFrame = screenFrame
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(Palette.dim.cgColor)
        context.fill(bounds)

        if let currentPoint = session.currentPoint(in: screenFrame), session.isDragging {
            drawReticle(at: currentPoint, in: context)
        }

        guard let selectionRect = session.selectionRect(in: screenFrame) else { return }

        let path = CGPath(
            roundedRect: selectionRect,
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )

        context.saveGState()
        context.setBlendMode(.clear)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()

        context.setFillColor(Palette.selectionFill.cgColor)
        context.addPath(path)
        context.fillPath()

        context.saveGState()
        context.setShadow(offset: .zero, blur: 24, color: Palette.selectionGlow.cgColor)
        context.setStrokeColor(Palette.selectionStroke.cgColor)
        context.setLineWidth(2)
        context.addPath(path)
        context.strokePath()
        context.restoreGState()

        drawCornerAccents(for: selectionRect, in: context)

        if let currentPoint = session.currentPoint(in: screenFrame), let dimensionsText = session.dimensionsText() {
            drawHUD(text: dimensionsText, anchor: currentPoint, selectionRect: selectionRect, in: context)
        }
    }

    override func mouseDown(with event: NSEvent) {
        session.beginDrag(at: globalPoint(from: event))
    }

    override func mouseDragged(with event: NSEvent) {
        session.updateDrag(to: globalPoint(from: event))
    }

    override func mouseUp(with event: NSEvent) {
        session.finishDrag(at: globalPoint(from: event))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelSelection()
            return
        }

        super.keyDown(with: event)
    }

    func cancelSelection() {
        session.finish(with: .cancelled)
    }

    private func globalPoint(from event: NSEvent) -> CGPoint {
        guard let window else { return .zero }
        return window.convertPoint(toScreen: event.locationInWindow)
    }

    private func drawReticle(at point: CGPoint, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(Palette.reticle.cgColor)
        context.setLineWidth(1)

        context.move(to: CGPoint(x: point.x, y: bounds.minY))
        context.addLine(to: CGPoint(x: point.x, y: bounds.maxY))
        context.move(to: CGPoint(x: bounds.minX, y: point.y))
        context.addLine(to: CGPoint(x: bounds.maxX, y: point.y))
        context.strokePath()
        context.restoreGState()
    }

    private func drawCornerAccents(for rect: CGRect, in context: CGContext) {
        let accentLength = min(24, min(rect.width, rect.height) / 3)
        guard accentLength > 0 else { return }

        context.saveGState()
        context.setStrokeColor(Palette.selectionStroke.cgColor)
        context.setLineWidth(3)
        context.setLineCap(.round)

        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + accentLength, y: rect.minY), CGPoint(x: rect.minX, y: rect.minY + accentLength)),
            (CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX - accentLength, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + accentLength)),
            (CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX + accentLength, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - accentLength)),
            (CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - accentLength, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY - accentLength))
        ]

        for corner in corners {
            context.move(to: corner.0)
            context.addLine(to: corner.1)
            context.move(to: corner.0)
            context.addLine(to: corner.2)
        }

        context.strokePath()
        context.restoreGState()
    }

    private func drawHUD(
        text: String,
        anchor: CGPoint,
        selectionRect: CGRect,
        in context: CGContext
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: Palette.hudText
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()

        let bubbleSize = CGSize(width: textSize.width + 20, height: textSize.height + 10)
        let preferredOrigin = CGPoint(x: anchor.x + 18, y: selectionRect.maxY + 14)
        let clampedX = min(max(bounds.minX + 14, preferredOrigin.x), bounds.maxX - bubbleSize.width - 14)
        let prefersAbove = preferredOrigin.y + bubbleSize.height <= bounds.maxY - 14
        let originY = prefersAbove
            ? preferredOrigin.y
            : max(bounds.minY + 14, selectionRect.minY - bubbleSize.height - 14)

        let bubbleRect = CGRect(origin: CGPoint(x: clampedX, y: originY), size: bubbleSize)
        let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: 12, yRadius: 12)

        Palette.hudFill.setFill()
        bubblePath.fill()

        Palette.hudStroke.setStroke()
        bubblePath.lineWidth = 1
        bubblePath.stroke()

        attributedText.draw(at: CGPoint(x: bubbleRect.minX + 10, y: bubbleRect.minY + 5))
    }
}
