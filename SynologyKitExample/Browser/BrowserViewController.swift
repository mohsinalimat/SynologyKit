//
//  BrowserViewController.swift
//  SynologyKitExample
//
//  Created by xu.shuifeng on 2019/11/6.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import UIKit
import SynologyKit
import WXActionSheet
import Alamofire

class BrowserViewController: UIViewController {
    
    var folderPath: String?
    
    var dataSource: [BrowserModel] = []
    
    private var tableView: UITableView!
    
    private let client: SynologyClient
    
    init(client: SynologyClient) {
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
        setupNavigationBar()
        setupTableView()
        loadData()
    }
    
    private func setupNavigationBar() {
        if title == nil {
            title = "Browse"
            
            let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(handleCloseButtonClicked))
            navigationItem.leftBarButtonItem = closeButton
        }
        view.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = .white
        
        let moreButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(handleActionButtonClicked))
        navigationItem.rightBarButtonItem = moreButton
    }

    @objc private func handleCloseButtonClicked() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc private func handleActionButtonClicked() {
        showMoreContext()
    }
    
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.register(BrowserTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(BrowserTableViewCell.self))
        view.addSubview(tableView)
    }
    
    private func loadData() {
        if let path = folderPath {
            loadFolderFiles(path)
        } else {
            loadShareFolders()
        }
    }
    
    private func loadFolderFiles(_ folder: String) {
        client.listFolder(folder) { response in
            switch response {
            case .success(let result):
                if let files = result.files {
                    self.dataSource = files.map { BrowserModel(name: $0.name, path: $0.path, isDirectory: $0.isdir) }
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func loadShareFolders() {
        
        client.listShareFolders { response in
            switch response {
            case .success(let result):
                if let shares = result.shares {
                    self.dataSource = shares.map { BrowserModel(name: $0.name, path: $0.path, isDirectory: $0.isdir) }
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func navigateToFolderViewController(_ folder: String, name: String?) {
        let controller = BrowserViewController(client: client)
        controller.folderPath = folder
        controller.title = name
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension BrowserViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BrowserTableViewCell.self), for: indexPath) as! BrowserTableViewCell
        cell.delegate = self
        let model = dataSource[indexPath.row]
        cell.update(model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let file = dataSource[indexPath.row]
        if file.isDirectory {
            navigateToFolderViewController(file.path, name: file.name)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56.0
    }
}

// MARK: - BrowserTableViewCellDelegate
extension BrowserViewController: BrowserTableViewCellDelegate {
    
    func didTapMoreButton(model: BrowserModel) {
        let actionSheet = WXActionSheet(cancelButtonTitle: "Cancel")
        actionSheet.add(WXActionSheetItem(title: "MD5", handler: { [weak self] _ in
            self?.calculateMD5(of: model)
        }))
        if !model.isDirectory {
            actionSheet.add(WXActionSheetItem(title: "Download", handler: { [weak self] _ in
                self?.downloadFile(model)
            }))
        }
        
        actionSheet.show()
    }
    
    private func calculateMD5(of file: BrowserModel) {
        client.md5(ofFile: file.path) { response in
            switch response {
            case .success(let task):
                if let md5 = task.md5 {
                    print(md5)
                }
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    private func downloadFile(_ file: BrowserModel) {
        let destination: DownloadRequest.DownloadFileDestination = { (temporaryURL, response)  in
            let options = DownloadRequest.DownloadOptions.removePreviousFile
            let localURL = URL(fileURLWithPath: NSHomeDirectory().appending("/Documents/\(file.name)"))
            return (localURL,options)
        }
        
        client.downloadFile(path: file.path, to: destination).downloadProgress { progress in
            print(progress)
        }.response { response in
            if response.error == nil, let path = response.destinationURL?.path {
                print("File Downloaded to :\(path)")
            }
        }
    }
    
    private func showMoreContext() {
        let actionSheet = WXActionSheet(cancelButtonTitle: "Cancel")
        actionSheet.add(WXActionSheetItem(title: "Upload", handler: { [weak self] _ in
            self?.uploadFile()
        }))
        actionSheet.show()
    }
    
    private func uploadFile() {
        
        guard let path = Bundle.main.path(forResource: "Test", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)), let folder = folderPath else {
            return
        }
        
        client.upload(data: data, filename: "test.json", destinationFolderPath: folder, createParents: true, options: nil) { result in
            switch result {
            case .success(let request, _, _):
                request.uploadProgress { progress in
                    print(progress)
                }.response { response in
                    if response.error == nil {
                        print("Uploaded")
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
        
    }
}
