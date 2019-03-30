
//
//  FileListController.swift
//  txt.rdr WatchKit Extension
//
//  Created by spoonik on 2016/04/14.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class FileListController: WKInterfaceController, NotifyReceivedNewFileDelegate {
    @IBOutlet var emptyLabel: WKInterfaceLabel!
    @IBOutlet var syncButton: WKInterfaceButton!
    @IBOutlet var table: WKInterfaceTable!
  
    var delegate: NotifyReceivedNewFileDelegate! = nil
    var bookManager = BookManager.sharedManager
    let bookInfo = BookManager.sharedManager.getOpenedBook()
    let docsDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    var items: [String]!
  
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        let pageController: TextPageController = (context as? TextPageController)!
        delegate = pageController
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        // TOC情報のアップデート
        bookManager.registerFileListController(self)
        bookManager.update()
        reloadTable()
    }
    func notifyNewFile(_ context:String) {
        bookManager.update()
        reloadTable()
    }

    // テーブルにファイル名リストをセット
    func reloadTable() {
        table.setNumberOfRows(bookManager.getFileCount(), withRowType: "FileTableRow")
        for index in 0..<bookManager.getFileCount() {
            let row = table.rowController(at: index) as! FilesTableRow
            row.fileLabel.setText(bookManager.getFileNameAt(index))
            row.groupBox.setBackgroundColor( (index==0)
                      ? UIColor(red:1.0,green:0.9,blue:0.1,alpha:1.0)   //先頭のものが自動選択されることを示すため明るく表示
                      : UIColor(red:1.0,green:0.8,blue:0.0,alpha:1.0))
        }
        emptyLabel.setHidden(bookManager.getFileCount() > 0)
    }

    // ファイルの選択によるViewの移動
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        bookManager.openABook(rowIndex)
        dismiss()
    }

    @IBAction func pushSyncButton() {
        bookManager.update()
        reloadTable()
    }
  
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
      
        delegate.notifyNewFile("")
    }

}
