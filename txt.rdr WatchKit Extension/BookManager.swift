//
//  BookManager.swift
//  txt.rdr
//
//  Created by spoonik on 2016/04/16.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


// ファイル受信を知らせてくれるプロトコル
protocol NotifyReceivedNewFileDelegate {
    func notifyNewFile(_ context:String)
}

// パス名からファイル名を取り出すユーティリティ関数
func getFilePathComponent(_ path: String) -> String {
    let pathEncoded = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    let url = URL(string: pathEncoded)!
    let filename = url.lastPathComponent
    return filename
}

class BookManager: NSObject, WCSessionDelegate {
    let docsDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let filemgr = FileManager.default
    var textPageController: TextPageController? = nil
    var fileListController: FileListController? = nil
    var toctable: Array<BookInfo> = []   //plist

    // Singleton Pattern : BookManager.sharedManager でインスタンスを取得
    //let sharedManager = BookManager()
    static let sharedManager: BookManager = {
        let instance = BookManager()
        return instance
    }()
  
    fileprivate override init() {
        //前回のTOCの展開状態をplistから取得：変数の初期化なのでsuper.initより前
        toctable = BookDBUtility.getTocController()

        super.init()

        // iOSからのファイル受信をするセッションを開始
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self // conforms to WCSessionDelegate
            session.activate()
        }

        // TOC更新
        self.update()
    }

    // notify用にコントローラを登録
    func registerTextPageController(_ controller: TextPageController) {
        textPageController = controller
    }
    func registerFileListController(_ controller: FileListController) {
        fileListController = controller
    }
  
    // iOSからのファイル受信セッション
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    @nonobjc public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject] = [:]){
        // iOS11でiCloudファイルの送信がうまくできなくなったために作ろうとした回避策。結局、送信サイズの上限が小さく、使えなかった
        let filename : String = userInfo["name"] as! String
        let content : NSString = userInfo["content"] as! NSString
        print(filename)
        NSLog("session did receive application context")
      
        // Documentsフォルダに受信ファイルを保存
        do {
            let tomovefile = docsDir + "/" + filename
            if filemgr.fileExists(atPath: tomovefile) {
                try filemgr.removeItem(atPath: tomovefile)    // 同じファイルがあれば先に削除しておく
            }
            // ファイルに保存する
            try content.write( toFile: tomovefile, atomically: false, encoding: String.Encoding.utf8.rawValue )
            //try filemgr.moveItem(atPath: file.fileURL.path, toPath: tomovefile)
        } catch let error as NSError {
            print("Error moving file: \(error.description)")
        }

        // TOC更新
        self.update()
      
        // Controllerがあれば通知
        if textPageController != nil {
            textPageController!.notifyNewFile(filename)
        }
        if fileListController != nil {
            fileListController!.notifyNewFile(filename)
        }
      
    }
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        NSLog("session did receive userinfo Finished")
    }
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let filename = getFilePathComponent(file.fileURL.path)   // ファイル名は送信元と同じものがくる
    
        // 同期中の文字列表示
        WKInterfaceDevice.current().play( WKHapticType.start )

        // Documentsフォルダに受信ファイルを保存
        do {
            let tomovefile = docsDir + "/" + filename
            if filemgr.fileExists(atPath: tomovefile) {
                try filemgr.removeItem(atPath: tomovefile)    // 同じファイルがあれば先に削除しておく
            }
            // Documentsフォルダに移動する
            try filemgr.moveItem(atPath: file.fileURL.path, toPath: tomovefile)
        } catch let error as NSError {
            print("Error moving file: \(error.description)")
        }

        // TOC更新
        self.update()
      
        // Controllerがあれば通知
        if textPageController != nil {
            textPageController!.notifyNewFile(filename)
        }
        if fileListController != nil {
            fileListController!.notifyNewFile(filename)
        }
      
    }


    // ブックの情報の更新。すべてのファイルを舐めて、全体を更新する
    func update() {
        var fileList: Array<String> = []
        var newTocTable: Array<BookInfo> = []

        do {
            // Documentsフォルダから.txtのリストを取得
            let list = try filemgr.contentsOfDirectory(atPath: docsDir)
            for filename in list {
                if filename.hasSuffix(".txt") {
                    let success = updateTocAt(docsDir + "/" + filename)
                    if success {
                        fileList.append(filename)
                    }
                }
            }
        } catch let error as NSError {
            print("Error moving file: \(error.description)")
        }
      
        // plistに残っているゴミエントリーを削除
        for entry in toctable {
            for filename in fileList {
                if entry.filename == filename {
                    newTocTable.append(entry)
                    break
                }
            }
        }
        toctable = newTocTable

        // plistにセット
        BookDBUtility.saveTocController(toctable, syncnow: true)
    }
  
    // 1つのブック情報の更新。ファイルを開き、TOCを生成する
    func updateTocAt(_ filepath: String) -> Bool {
        let filename = getFilePathComponent(filepath)
        var alreadyExists = false
      
        // plistにすでに最新の情報が入っているファイルか？
        for i in (0..<toctable.count).reversed() {
        
            if filename == toctable[i].filename {   // ファイル名は同じか？
              
                do {    // ファイルサイズは同じか？ > continue
                    if let attr: NSDictionary = try FileManager.default.attributesOfItem(atPath: filepath) as NSDictionary? {
                        if attr.fileSize() == toctable[i].filesize {
                            if !alreadyExists {
                                alreadyExists = true
                            } else {
                                // 重複したTOCのエントリーを削除
                                toctable.remove(at: i)
                            }
                            continue
                        }
                    }
                  
                    // 古いTOCのエントリーを削除
                    toctable.remove(at: i)

                } catch let error as NSError {
                    print("Error moving file: \(error.description)")
                    return false
                }
            }
        }
    
        if !alreadyExists {
            // 新しくTOCを生成
            let newBook = BookInfo(filepath: filepath)
            if newBook.isValid() {
                toctable.append(newBook)
                WKInterfaceDevice.current().play( WKHapticType.success )
            } else {
                return false
            }
        }
        return true
    }
  
    // Table RowIndexの本を開き、toctable上の先頭「index=0」に移動する。最後に開いたものが常に先頭に来る仕様
    func openABook(_ rowIndex: Int) {
        let temptoc = toctable[rowIndex]
        toctable.remove(at: rowIndex)
        toctable.insert(temptoc, at: 0)
    }
  
    func getBookProgress() -> Float {
        let book: BookInfo? = getOpenedBook()
        if book == nil {
            return 0.7
        }
        let bookmark = Float(book!.bookmark)
        let maxpage = Float(book!.maxpagelen)
        if maxpage <= 0.0 {
            return 0.0
        }
        return  bookmark/maxpage
    }
    func getBookInitial() -> String {
        let book: BookInfo? = getOpenedBook()
        if book == nil {
            return "mT"
        }
        let filename: String = book!.filename
        return filename.substring(to: filename.index(filename.startIndex, offsetBy: 1))
    }
  
    func eraseOneBook(_ filename: String) {
        do {
            if filename.hasSuffix(".txt") {
                let tomovefile = docsDir + "/" + filename
                if filemgr.fileExists(atPath: tomovefile) {
                    try filemgr.removeItem(atPath: tomovefile)
                }
            }
        } catch let error as NSError {
            print("Error moving file: \(error.description)")
        }
      
        for i in 0..<toctable.count {
            if toctable[i].filename == filename {
                toctable.remove(at: i)
                break
            }
        }

        // plistにセット
        BookDBUtility.saveTocController(toctable, syncnow: true)
    }
  
    // 開いているブックの情報を返す
    func getOpenedBook() -> BookInfo? {
        return (toctable.count > 0) ? toctable[0] : nil
    }
    // i番目のファイル名を返す
    func getFileNameAt(_ i: Int) -> String! {
        return (i < toctable.count) ? toctable[i].filename : nil
    }
    // 現在保持しているファイル数を返す
    func getFileCount() -> Int {
        return toctable.count
    }

}
