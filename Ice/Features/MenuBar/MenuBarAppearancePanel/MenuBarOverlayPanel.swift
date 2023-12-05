//
//  MenuBarOverlayPanel.swift
//  Ice
//

import Cocoa
import Combine

// MARK: - MenuBarOverlayPanel

class MenuBarOverlayPanel: MenuBarAppearancePanel {
    override var canShow: Bool {
        guard let menuBar else {
            return false
        }
        return menuBar.shapeKind != .none || menuBar.tintKind != .none
    }

    init(menuBar: MenuBar) {
        super.init(level: .statusBar, menuBar: menuBar)
        self.contentView = MenuBarOverlayPanelView(menuBar: menuBar)
    }
}

// MARK: - MenuBarOverlayPanelView

private class MenuBarOverlayPanelView: NSView {
    private weak var menuBar: MenuBar?
    private var cancellable: (any Cancellable)?

    init(menuBar: MenuBar) {
        super.init(frame: .zero)
        self.menuBar = menuBar
        self.cancellable = Publishers.CombineLatest4(
            menuBar.$desktopWallpaper,
            menuBar.$tintKind,
            menuBar.$tintColor,
            menuBar.$tintGradient
        )
        .combineLatest(
            menuBar.$shapeKind,
            menuBar.$fullShapeInfo,
            menuBar.$splitShapeInfo
        )
        .sink { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        defer {
            NSGraphicsContext.restoreGraphicsState()
        }

        guard let menuBar else {
            return
        }

        switch menuBar.shapeKind {
        case .none:
            break
        case .full:
            let clipBounds = CGRect(
                x: bounds.height / 2,
                y: 0,
                width: bounds.width - bounds.height,
                height: bounds.height
            )
            let leadingEndCapBounds = CGRect(
                x: 0,
                y: 0,
                width: bounds.height,
                height: bounds.height
            )
            let trailingEndCapBounds = CGRect(
                x: bounds.width - bounds.height,
                y: 0,
                width: bounds.height,
                height: bounds.height
            )

            var clipPath = NSBezierPath(rect: clipBounds)

            switch menuBar.fullShapeInfo.leadingEndCap {
            case .square:
                clipPath = NSBezierPath(
                    cgPath: clipPath.cgPath.union(
                        CGPath(rect: leadingEndCapBounds, transform: nil)
                    )
                )
            case .round:
                clipPath = NSBezierPath(
                    cgPath: clipPath.cgPath.union(
                        CGPath(ellipseIn: leadingEndCapBounds, transform: nil)
                    )
                )
            }

            switch menuBar.fullShapeInfo.trailingEndCap {
            case .square:
                clipPath = NSBezierPath(
                    cgPath: clipPath.cgPath.union(
                        CGPath(rect: trailingEndCapBounds, transform: nil)
                    )
                )
            case .round:
                clipPath = NSBezierPath(
                    cgPath: clipPath.cgPath.union(
                        CGPath(ellipseIn: trailingEndCapBounds, transform: nil)
                    )
                )
            }

            if let desktopWallpaper = menuBar.desktopWallpaper {
                let reversedClipPath = NSBezierPath(rect: bounds)
                reversedClipPath.append(clipPath.reversed)
                reversedClipPath.setClip()
                NSGraphicsContext.current?.cgContext.draw(desktopWallpaper, in: bounds, byTiling: false)
            }

            clipPath.setClip()
        case .split:
            break
        }

        switch menuBar.tintKind {
        case .none:
            break
        case .solid:
            NSColor(cgColor: menuBar.tintColor)?.withAlphaComponent(0.2).setFill()
            NSBezierPath(rect: bounds).fill()
        case .gradient:
            menuBar.tintGradient.withAlphaComponent(0.2).nsGradient?.draw(in: bounds, angle: 0)
        }
    }
}
