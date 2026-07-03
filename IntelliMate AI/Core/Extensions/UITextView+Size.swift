//
//  UITextView+Size.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//

import UIKit

extension UITextView {
    func calculatedHeight() -> CGFloat {
        let fittingSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        return sizeThatFits(fittingSize).height
    }
}
