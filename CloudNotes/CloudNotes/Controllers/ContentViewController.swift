//
//  ContentViewController.swift
//  CloudNotes
//
//  Created by 강인희 on 2021/02/16.
//

import UIKit

class ContentViewController: UIViewController {
    private let headLinefont = UIFont.boldSystemFont(ofSize: 24)
    private let bodyLinefont = UIFont.systemFont(ofSize: 15)
    private var currentMemo: Memo?
    weak var delegate: MemoDelegate?
    
    private var popoverController: UIPopoverPresentationController?
    private var activityViewController: UIActivityViewController?
    private lazy var alertController: UIAlertController = {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let alertActions = [shareAction, deleteAction, UIAlertAction(title: AlertController.MoreActionSheet.cancel, style: .cancel, handler: nil)]
        
        for action in alertActions {
            alertController.addAction(action)
        }
        
        return alertController
    }()
    
    private lazy var shareAction: UIAlertAction = {
        let shareAction = UIAlertAction(title: AlertController.MoreActionSheet.share, style: .default, handler: { (alert: UIAlertAction!) -> Void in
            guard let sharingMessage = self.contentView.text else {
                return
            }
            
            self.activityViewController = UIActivityViewController(activityItems: [sharingMessage], applicationActivities: nil)
            guard let activityViewController = self.activityViewController,
                  let popoverController = activityViewController.popoverPresentationController else {
                return
            }
            
            self.popoverController = popoverController
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            
            self.present(activityViewController, animated: true, completion: nil)
        })
        
        return shareAction
    }()
    
    private lazy var deleteAction: UIAlertAction = {
        let deleteAction = UIAlertAction(title: AlertController.MoreActionSheet.delete, style: .destructive, handler: { (alert: UIAlertAction!) -> Void in
            let alertController = UIAlertController(title: AlertController.MemoDeleteAlert.title, message: AlertController.MemoDeleteAlert.message, preferredStyle: .alert)
            
            let deleteCancelAction = UIAlertAction(title: AlertController.MemoDeleteAlert.cancelAction, style: .cancel, handler: nil)
            let deleteCompleteAction = UIAlertAction(title: AlertController.MemoDeleteAlert.deleteAction, style: .destructive, handler: { _  in
                if let mainVC = self.splitViewController as? MainViewController,
                   let currentMemo = self.currentMemo {
                    let masterVC = mainVC.masterViewController
                    self.delegate = masterVC
                    
                    self.delegate?.deleteMemo(memo: currentMemo)
                    self.navigationController?.popToRootViewController(animated: false)
                }
            })
            
            alertController.addAction(deleteCancelAction)
            alertController.addAction(deleteCompleteAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
        
        return deleteAction
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .white
        return scrollView
    }()
    
    private lazy var contentView: MemoTextView = {
        let contentView = MemoTextView()
        contentView.delegate = self
        contentView.backgroundColor = .white
        contentView.isScrollEnabled = false
        contentView.isEditable = false
        //TODO: autocorrectionType과 isUserInteractionEnabled 생각해보기
        contentView.autocorrectionType = .no
        contentView.isUserInteractionEnabled = true
        contentView.dataDetectorTypes = .all
        return contentView
    }()
    
    private lazy var optionButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action:  #selector(didTapOptionButton(_:)))
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = optionButton
        view.backgroundColor = .white
        setUpConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let mainVC = self.splitViewController as? MainViewController,
           let modifiedContents = modifyContents() {
            let masterVC = mainVC.masterViewController
            self.delegate = masterVC
            delegate?.updateMemo(memo: modifiedContents)
        }
    }

    //FIXME: 호출이 안되는 것 같습니다. 이 부분이 아이폰 공유화면일까요? 확인 부탁드려요!
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let activityViewController = self.activityViewController,
              let popoverController = activityViewController.popoverPresentationController else {
            return
        }
        popoverController.sourceView = self.view
        popoverController.sourceRect = CGRect(x: size.width*0.5, y: size.height*0.5, width: 0, height: 0)
        popoverController.permittedArrowDirections = []
    }
    
    func didTapMemoItem(with memo: Memo) {
        self.currentMemo = memo
        updateUI(with: memo)
    }
}
extension ContentViewController {
    @objc private func keyboardWillShow(_ sender: Notification) {
        guard let userInfo = sender.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        scrollView.contentInset.bottom = keyboardFrame.size.height
    }
    
    @objc private func keyboardWillHide(_ sender: Notification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func didTapOptionButton(_ sender: UIBarButtonItem) {
        contentView.endEditing(true)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
}

extension ContentViewController {
    private func setUpConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }
    
    private func updateUI(with memo: Memo) {
        let memoAttributedString = NSMutableAttributedString(string: memo.title ?? .empty)
        let bodyAttributedString = NSMutableAttributedString(string: "\(String.EscapeSequence.newLine)\(memo.body ?? .empty)")
        memoAttributedString.addAttribute(.font, value: headLinefont, range: NSRange(location: 0, length: memo.title?.count ?? .zero))
        bodyAttributedString.addAttribute(.font, value: bodyLinefont, range: NSRange(location: 0, length: memo.body?.count ?? .zero))
        memoAttributedString.append(bodyAttributedString)
        contentView.attributedText = memoAttributedString
        updateTextViewSize()
    }
    
    private func updateTextViewSize() {
        let size = CGSize(width: self.view.frame.width, height: .infinity)
        let rearrangedSize = contentView.sizeThatFits(size)
        
        contentView.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = rearrangedSize.height
            }
        }
    }

    private func modifyContents() -> Memo?  {
        let startIndex: String.Index = contentView.text.startIndex
        guard let endIndex: String.Index = contentView.text.firstIndex(of: Character(String.EscapeSequence.newLine)) else { return Memo() }
        let afterEndIndex: String.Index = contentView.text.index(after: endIndex)
        
        
        let title: Substring = contentView.text[startIndex..<endIndex]
        let body: Substring = contentView.text[afterEndIndex...]
        if let currentMemo = self.currentMemo {
            currentMemo.title = String(title)
            currentMemo.body = String(body)
            return currentMemo
        }
        return currentMemo
    }
}

extension ContentViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewSize()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let headerAttributes: [NSAttributedString.Key: UIFont] = [.font: .boldSystemFont(ofSize: 24)]
        let bodyAttributes: [NSAttributedString.Key: UIFont] = [.font : .systemFont(ofSize: 15)]
        let textAsNSString: NSString = contentView.text as NSString
        let replaced: NSString = textAsNSString.replacingCharacters(in: range, with: text) as NSString
        let boldRange: NSRange = replaced.range(of: String.EscapeSequence.newLine)
        if boldRange.location <= range.location {
            contentView.typingAttributes = bodyAttributes
        } else {
            contentView.typingAttributes = headerAttributes
        }
        
        return true
    }
}
