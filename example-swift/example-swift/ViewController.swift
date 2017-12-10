//
//  ViewController.swift
//  Example
//
//  Created by Tatsuya Kitagawa on 2017/12/07.
//  Copyright © 2017年 BASE, Inc. All rights reserved.
//

import UIKit
import PAYJP

let PAYJPPublicKey = "pk_test_0383a1b8f91e8a6e3ea0e2a9"

class ViewController: UITableViewController {
    
    @IBOutlet weak var fieldCardNumber: UITextField!
    @IBOutlet weak var fieldCardCvc: UITextField!
    @IBOutlet weak var fieldCardMonth: UITextField!
    @IBOutlet weak var fieldCardYear: UITextField!
    @IBOutlet weak var labelTokenId: UILabel!
    
    lazy var payjpClient: PAYJP.APIClient = PAYJP.APIClient(publicKey: PAYJPPublicKey)
    
    enum CellSection: Int {
        case CardInformation = 0
        case CreateToken = 1
        case TokenId = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch CellSection(rawValue: indexPath.section) {
        case .CreateToken?:
            createToken()
            tableView.deselectRow(at: indexPath, animated: true)
        case .TokenId?:
            getToken()
            tableView.deselectRow(at: indexPath, animated: true)
        default: break
        }
    }
    
    private func createToken() {
        print("createToken")
        let number = fieldCardNumber.text ?? ""
        let cvc = fieldCardCvc.text ?? ""
        let month = fieldCardMonth.text ?? ""
        let year = fieldCardYear.text ?? ""
        print("input number=\(number), cvc=\(cvc), month=\(month), year=\(year)")
        payjpClient.createToken(
            with: number,
            cvc: cvc,
            expirationMonth: month,
            expirationYear: year)
        { [weak self] result in
            switch result {
            case .success(let token):
                DispatchQueue.main.async {
                    self?.labelTokenId.text = token.identifer
                    self?.tableView.reloadData()
                    self?.showToken(token: token)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.labelTokenId.text = ""
                    self?.showError(error: error)
                }
            }
        }
    }
    
    private func getToken() {
        let tokenId = labelTokenId.text ?? ""
        print("getToken with \(tokenId)")
        payjpClient.getToken(with: tokenId) { [weak self] result in
            switch result {
            case .success(let token):
                DispatchQueue.main.async {
                    self?.labelTokenId.text = token.identifer
                    self?.tableView.reloadData()
                    self?.showToken(token: token)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.labelTokenId.text = ""
                    self?.showError(error: error)
                }
            }
        }
    }
    
    private func showToken(token: Token) {
        let alert = UIAlertController(
            title: "success",
            message: token.display,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showError(error: Error) {
        let alert = UIAlertController(
            title: "error",
            message: error.localizedDescription,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

private extension Token {
    var display: String {
        return "id=\(identifer),\n"
            + "card.id=\(card.identifer),\n"
            + "card.last4=\(card.last4Number)\n,"
            + "card.exp=\(card.expirationMonth)/\(card.expirationYear)"
    }
}
