import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeViews(rows: rows, in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            if size.width > remainingWidth {
                currentRow += 1
                rows.append([])
                remainingWidth = (proposal.width ?? 0) - size.width - spacing
            } else {
                remainingWidth -= size.width + spacing
            }
            rows[currentRow].append(subview)
        }
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubview]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        var width: CGFloat = 0
        
        for row in rows {
            var rowWidth: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in row {
                let size = subview.sizeThatFits(proposal)
                rowWidth += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            width = max(width, rowWidth)
            height += maxHeight + spacing
        }
        
        return CGSize(width: width - spacing, height: height - spacing)
    }
    
    private func placeViews(rows: [[LayoutSubview]], in bounds: CGRect) {
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            var maxHeight: CGFloat = 0
            
            // 计算当前行的最大高度
            for subview in row {
                let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                maxHeight = max(maxHeight, size.height)
            }
            
            // 放置视图
            for subview in row {
                let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subview.place(
                    at: CGPoint(x: x, y: y + (maxHeight - size.height) / 2),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
            }
            
            y += maxHeight + spacing
        }
    }
} 