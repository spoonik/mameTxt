 //
//  ViewController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/04/14.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import UIKit
import WatchConnectivity

class CloudFileInfo {
    var name: String = ""
    var url: URL = URL(string: "http://www.google.com")!
    var size: Int = 0
}

class ViewController: UITableViewController, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    //@available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
      
    }
    public func sessionDidBecomeInactive(_ session: WCSession) {
      
    }
    public func sessionDidDeactivate(_ session: WCSession) {
      
    }

    let MAXSUPPORTFILESIZE: UInt64 = 20971520    //20MBのファイルまでしか扱えない

    let instructionLocal = "Swipe to transfer file"
    let instructionCloud = "iCloud Drive"
    var storageTypeNum = 1

    @IBOutlet var table: UITableView!
    var bookListLocal: Array<String> = []
    var bookListiCloud: Array<CloudFileInfo> = []

    var docsDir: String = ""
    var iCloudDrive: URL = URL(string: "http://www.google.com")!
  
    let metadataQuery = NSMetadataQuery()
  
    let filemanager = FileManager.default

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      
        // Watchからの送信データを受信するセッションを開始
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self // conforms to WCSessionDelegate
            session.activate()
        }
      
        // Refresh(テーブルを下に引っ張って更新する)の登録
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewController.updateView), for: UIControlEvents.valueChanged)
        self.refreshControl = refreshControl
      
      
        // Documentsフォルダのパスを取得
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        docsDir = dirPaths[0] as String
      
        // テーブルを更新
        updateView()
      
    }
  
    @objc func updateView() {
        do {
        
            // LocalのDocumentsフォルダから.txtのリストを取得
            self.bookListLocal = []
            let list = try filemanager.contentsOfDirectory(atPath: docsDir)
            for filename in list {
                if filename.hasSuffix(".txt") {
                    bookListLocal.append(filename)
                }
            }
          
            // iCloud Driveの初期化
            if prepareiCloudDrive() {
            
                // iCloud利用可能ならファイル検索を投げておく
                NotificationCenter.default.addObserver(self,
                              selector: #selector(ViewController.handleMetadataQueryFinished(_:)),
                              name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                              object: nil)
                startQuery()
              
                storageTypeNum = 2
            } else {
                storageTypeNum = 1  //Localフォルダのみ
            }
          
        } catch let error as NSError {
            print("Error moving file: \(error.description)")
            self.refreshControl?.endRefreshing()
        }
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
  
    // iCloud Driveを生成
    func prepareiCloudDrive() -> Bool {
      
        let fileManager = FileManager()
        do {
            if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
                iCloudDrive = iCloudURL.appendingPathComponent("Documents")
                // フォルダを生成(上書きで生成してもファイルは消えない)
                try fileManager.createDirectory(at: iCloudDrive, withIntermediateDirectories: true, attributes: nil)

                //Add txt file to my local folder
                let myTextString = NSString(string: "Place your text files in this folder")
                let myLocalFile = iCloudDrive.appendingPathComponent("_PlaceYourTxtFiles_")
                try _ = myTextString.write(to: myLocalFile, atomically: true, encoding: String.Encoding.utf8.rawValue)

            }
        } catch let error as NSError {
            print("Error creation: \(error.description)")
            self.refreshControl?.endRefreshing()
            return false
        }
        return true
    }
  
    // iCloudのファイルのリストを取得する方法は、Queryしてみるのが正しい
    func startQuery(){
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        let predicate = NSPredicate(format: "%K like %@",
          NSMetadataItemFSNameKey,
          "*.txt")
        
        metadataQuery.predicate = predicate
        if metadataQuery.start(){
          print("Successfully started the query.")
        } else {
          print("Failed to start the query.")
        }
    }
    @objc func handleMetadataQueryFinished(_ sender: NSMetadataQuery){

        NotificationCenter.default.removeObserver(self)
        metadataQuery.disableUpdates()
        metadataQuery.stop()
      
        bookListiCloud = []
      
        for item in metadataQuery.results as! [NSMetadataItem]{
          
            let itemName = item.value(forAttribute: NSMetadataItemFSNameKey) as! String
            let itemUrl = item.value(forAttribute: NSMetadataItemURLKey) as! URL
            let itemSize = item.value(forAttribute: NSMetadataItemFSSizeKey) as! Int
            print("Item name = \(itemName)")
            print("Item url = \(itemUrl)")
            print("Item size = \(itemSize)")
            
            let cloudfile: CloudFileInfo = CloudFileInfo()
            cloudfile.name = itemName
            cloudfile.url = itemUrl
            cloudfile.size = itemSize
            bookListiCloud.append(cloudfile)
        }
      
        // ファイル名でソート
        bookListiCloud.sort { $0.name < $1.name }
      
        // tableの再表示
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }

    // スワイプしてメニューを表示するようにButtonを拡張する
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
 
        // Sendボタン
        let sendButton: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "Sync") { (action, index) -> Void in
            tableView.isEditing = false

          // ファイルチェック
          // UTF-8かどうか
          let isUTF = self.isFileUTF8((indexPath as NSIndexPath).section, index: (indexPath as NSIndexPath).row)
          if isUTF.0 == false {
              self.errorMessage("This file is not UTF-8 encoding")
              return
          } // 成功したら、ここでファイルはダウンロードされているので後続の処理ではダウンロード不要
        
          // MAXSUPPORTFILESIZEのサイズ以下か
          let filesize = self.getFileSize((indexPath as NSIndexPath).section, index: (indexPath as NSIndexPath).row)
          if filesize > self.MAXSUPPORTFILESIZE || filesize == 0 {
              self.errorMessage("This file is larger than 5MB or 0byte")
              return
          }
        

          // Watchへのファイル送信をするセッションを開始
          if (WCSession.isSupported()) {
            let session = WCSession.default
            let olddelegate:WCSessionDelegate  = session.delegate!
            session.delegate = self
            session.activate()
          
            // ORIGINAL (until V2.4.0)
            //let fileurl = self.getFileURLName((indexPath as NSIndexPath).section, index: (indexPath as NSIndexPath).row)
            //session.transferFile(fileurl, metadata: nil)

            // iOS11で上記の方法ではiCloudファイルの送信がうまくできなくなったために作った回避策 V1
            let copiedfile = self.copyFileToTemp(content: isUTF.1!, fileName: self.getFileName((indexPath as NSIndexPath).section, index: (indexPath as NSIndexPath).row))
            if copiedfile == nil {
                self.errorMessage("File processing failed")
                return
            }
            let fileurl = URL(fileURLWithPath: copiedfile!)
            session.transferFile(fileurl, metadata: nil)
            
            // iOS11でiCloudファイルの送信がうまくできなくなったために作った回避策 V2。結局送信サイズ制限で使えなかった
            //let userInfo = ["name" : self.getFileName((indexPath as NSIndexPath).section, index: (indexPath as NSIndexPath).row), "content" : isUTF.1] as [String : Any]
            //session.transferUserInfo(userInfo)

            session.delegate = olddelegate
          }
        }
        sendButton.backgroundColor = UIColor(red:1.0,green:0.7,blue:0.0,alpha:1.0)
        return [sendButton]


    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return storageTypeNum
    }
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return bookListLocal.count
        } else if section == 1 {
            return bookListiCloud.count
        }
        return 0
    }
    
    // Tableのセクション区切りに操作説明を表示
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return instructionLocal
        } else if section == 1 {
            return instructionCloud
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell", for: indexPath)
        cell.textLabel?.text = getFileName((indexPath as NSIndexPath).section, index: (indexPath as NSIndexPath).row)
        return cell
    }
  
    func getFileName(_ section: Int, index: Int) -> String {
        if section == 0 {
            return bookListLocal[index]
        } else {
            return bookListiCloud[index].name
        }
    }
    func getFilePathName(_ section: Int, index: Int) -> String {
        if section == 0 {
            return docsDir + "/" + self.bookListLocal[index]
        } else {
            return bookListiCloud[index].url.path
        }
    }
    func getFileURLName(_ section: Int, index: Int) -> URL {
        if section == 0 {
            let filepath = docsDir + "/" + self.bookListLocal[index]
            return URL(fileURLWithPath: filepath)
        } else {
            return bookListiCloud[index].url
        }
    }
    func getFileSize(_ section: Int, index: Int) -> UInt64 {
        if index < bookListLocal.count {
            let filepath = getFilePathName(section, index: index)
            do {
                if let attr: NSDictionary = try filemanager.attributesOfItem(atPath: filepath) as NSDictionary? {
                    return attr.fileSize()
                }
            }
            catch let error as NSError {
                print("Error file read: \(error.description)")
                return 0
            }
        } else {
            return UInt64(bookListiCloud[index].size)
        }
    }
    func isFileUTF8(_ section: Int, index: Int) -> (Bool, NSString?) {
        let file = getFilePathName(section, index: index)
        var content: NSString? = nil
        
        // iCloudファイルなら、存在を確認して、なければダウンロードする
        do {
            if !filemanager.fileExists(atPath: file){
                let urlpath: URL = getFileURLName(section, index: index)
                // ファイルをダウンロード
                if filemanager.isUbiquitousItem(at: urlpath) {
                    try filemanager.startDownloadingUbiquitousItem(at: urlpath)
                }
            }
        } catch let error as NSError {
            print("\(error)")
            return (false, content)
        }

        let repeatTry: Int = 10  //この回数繰り返してみる。十分な数にしないとダウンロードエラーになる
        for i in 0..<repeatTry {
          Thread.sleep(forTimeInterval: 1.0)

          // String に転換してみて、UTF-8かどうかチェックする
          do {
              content = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue)
          }
          catch let error as NSError {
              print("\(error)")
              if i == (repeatTry - 1) {
                return (false, content)
              }
          }
        }
      
        return (true, content)
    }
  
    func copyFileToTemp(content: NSString, fileName: String) -> String? {
      do {
        let tempfolder: String = docsDir + "/" + "temp"
        let copyto: String = tempfolder + "/" + fileName
        try filemanager.createDirectory(atPath: tempfolder, withIntermediateDirectories: true, attributes: nil)

        if filemanager.fileExists(atPath: copyto) {
            try filemanager.removeItem(atPath: copyto)    // 同じファイルがあれば先に削除しておく
        }
        // ファイルに保存する
        try content.write( toFile: copyto, atomically: false, encoding: String.Encoding.utf8.rawValue )

        return copyto
      }
      catch let error as NSError {
          print("Ooops! Something went wrong: \(error)")
      }
      return nil
    }

    func errorMessage(_ message: String) {
        let alert:UIAlertController = UIAlertController(title:"Error",
                      message: message,
                      preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction:UIAlertAction = UIAlertAction(title: "OK",
                    style: UIAlertActionStyle.cancel,
                    handler:{
                    (action:UIAlertAction!) -> Void in
        })
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
    }

}

