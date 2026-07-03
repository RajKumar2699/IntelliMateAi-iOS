//
//  UITableView+Register.swift
//  IntelliMate AI
//
//  Created by Askme Technologies on 02/07/26.
//

import UIKit

extension UITableView {
    func register<T: UITableViewCell>(_ cellType: T.Type) {
        register(cellType, forCellReuseIdentifier: String(describing: cellType))
    }

    func dequeue<T: UITableViewCell>(_ cellType: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: String(describing: cellType), for: indexPath) as? T else {
            fatalError("Failed to dequeue \(String(describing: cellType))")
        }
        return cell
    }
}
