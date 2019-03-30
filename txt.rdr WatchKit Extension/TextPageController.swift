//
//  TextPageController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/04/16.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation
import MediaPlayer

var MAXFLIPPAGELENGTH: Int = 30    // 1自動めくりページに含める文字数。1バイト換算で

class TextPageController: WKInterfaceController, PageJumpControllerDelegate, NotifyReceivedNewFileDelegate, BookDeleteDelegate, SpeechSynthManagerAutoPageFlipDelegate {

    //@IBOutlet weak var volumeControl: WKInterfaceVolumeControl!
    @IBOutlet weak var voiceOverButton: WKInterfaceButton!
    @IBOutlet weak var voiceOverGroup: WKInterfaceGroup!
    @IBOutlet var table: WKInterfaceTable!
    @IBOutlet var pos: WKInterfaceLabel!
    
    var bookInfo: BookInfo? = nil
    var bookManager = BookManager.sharedManager
    var cacheText: String = ""
    var content: String = ""
  
    var autoFlipPointer: Int = 0
    var maxflippagelen: Int = MAXFLIPPAGELENGTH
    var maxflippagelen_forcecut: Int = MAXFLIPPAGELENGTH * 5 / 4
    var flashCardAnswer: String = ""
    var nowSpeeching = false
    
    var timer: Timer? = nil   // AutoFlip用のタイマー

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
      
        // Configure interface objects here.
        table.setNumberOfRows(1, withRowType: "FileTableRow")
        bookManager.registerTextPageController(self)
        SpeechSynthManager.sharedManager.setDelegate(delegate: self)
        
        // Remote Control Settings
        let commandCenter = MPRemoteCommandCenter.shared
        commandCenter().togglePlayPauseCommand.addTarget(self, action: #selector(togglePlayPause))
        commandCenter().playCommand.addTarget(self, action: #selector(continuePlay))
        commandCenter().pauseCommand.addTarget(self, action: #selector(pausePlay))
        commandCenter().nextTrackCommand.addTarget(self, action: #selector(skipForward))
        commandCenter().previousTrackCommand.addTarget(self, action: #selector(skipBackward))
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        openCurrentBook()
        resetSpeechButtonDisplay()
    }
    override func didAppear() {
        //openCurrentBook()
    }
  
    func notifyNewFile(_ context:String) {
        bookManager.update()
        openCurrentBook()
    }
  
    // カレントブックを開いて、そのブックのビューで表示する
    func openCurrentBook() {
        bookInfo = bookManager.getOpenedBook()
        if bookInfo != nil {
            bookInfo!.openBook()
            jumpToBookmarkPage()
        }
        switchViewMode()
    }
  
    @IBAction func pushVoiceOverButton() {
        nowSpeeching = !nowSpeeching
        SpeechSynthManager.sharedManager.restartSpeechText(start: nowSpeeching)
        resetSpeechButtonDisplay()
    }
    func resetSpeechButtonDisplay() {
        let (speechShow, _, _) = SettingsUtility.getSpeechSettings()
        voiceOverButton.setHidden(!speechShow)
        let voiceHide = (!speechShow || !nowSpeeching)
        //voiceOverGroup.setHidden(voiceHide)
        //volumeControl.setHidden(voiceHide)
        voiceOverButton.setTitle(nowSpeeching ? "VoiceOver ◼" : "VoiceOver ▶")
   }
    // ビューモードを切り替え、コンテンツを表示する
    func switchViewMode() {
        if bookInfo != nil {
            // ファイル名をタイトルに
            self.setTitle(bookInfo?.filename)
            setNormalViewMenu()
          
            switch bookInfo!.getViewMode() {
            case bookInfo!.SHUFFLEMODE:
                flashCardAnswer = ""
                reShuffle()
                setShuffleViewMenu()  // Shuffleコンテキストメニューに上書き
            case bookInfo!.AUTOFLIPMODE:    // 自動めくりモード
                flipPage()
            default:
                jumpToBookmarkPage()
            }
        }
        else {
            // タイトルを空に
            self.setTitle("")
            setEmptyContent()
            clearAllMenuItems()   //クリアしてから
            addMenuItem(with: UIImage(named:"openMenuIcon")!, title: "OpenFile", action: #selector(TextPageController.openAnotherTextFile))
        }
    }
    
    func callbackNextPage(terminated: Bool) {
        if terminated {
            stopReading()
        }
        else {
            jumpToBookmarkPage()
        }
    }

    // コンテンツの表示--------------------------------------
    // 指定のページを開く：ブックマークの位置、前後のページ
    func jumpToBookmarkPage() {
        autoFlipPointer = 0
        content = bookInfo!.getCurrentPageContent()
        // 表示中のブックマークを更新したBookInfoを保存する
        BookDBUtility.saveTocController(bookManager.toctable, syncnow: false)
    
        if (bookInfo!.getViewMode() == bookInfo!.AUTOFLIPMODE) {
            flipPage()
        } else {
            stopFlipTimer()

            // 1ページ分を表示・ページ位置を表示
            displayText(content)
            pos.setText("\((bookInfo?.bookmark)!)/\((bookInfo?.pagepos.count)!-1)")
        }
    
    }
    

    // flip page 自動めくり 1ページ分を表示
    @objc func flipPage() {
        var len = 0
        let nscontent: NSString = content as NSString

        if autoFlipPointer >= nscontent.length-1 {
            // 次のページに進む。jumpTo..では再度flipPageを呼ぶので、ここでreturnする
            _ = bookInfo!.openNextPage()
            jumpToBookmarkPage()
            return
        }

        // 区切り文字を見つけてページ区切りを設定する
        for i in autoFlipPointer..<nscontent.length {
            len = i - autoFlipPointer + 1

            let c = nscontent.character(at: i)
            if isDelimiter(c: c) {
                if len > maxflippagelen {     // キリのいいところでページを区切る
                    break
                }
            } else if len > maxflippagelen_forcecut {   // いい区切りがなくても、強制的に区切る
                break
            }
        }
      
        // flip 1ページ分を表示
        var flipcontent: String = nscontent.substring(with: NSRange(location: autoFlipPointer, length: len))  //連続改行を1改行に
        flipcontent = flipcontent.replacingOccurrences(of: "\n\n", with: "\n")
        flipcontent = flipcontent.replacingOccurrences(of: "\n\n", with: "\n")    //念のため2回呼んでおく
        while flipcontent[flipcontent.index(flipcontent.startIndex, offsetBy: 0)] == "\n" {  //先頭改行を削除
            flipcontent = String(flipcontent.dropFirst())
        }
        displayText(flipcontent)
        autoFlipPointer = autoFlipPointer + len

        if autoFlipPointer >= nscontent.length-1 {
            // 現ページの最後のflipページを表示したら、完了の意味でページ位置を表示
            pos.setText("\((bookInfo?.bookmark)!)/\((bookInfo?.pagepos.count)!-1)")
            stopFlipTimer()   // いったんタイマー止める
        }
        else {
            stopFlipTimer()
            var duration: Double = (bookInfo?.getAutoFlipSpeed())!
            duration = duration * Double((flipcontent as String).count) / Double(maxflippagelen)
            timer = Timer.scheduledTimer(timeInterval: duration,
                                           target: self,
                                           selector: #selector(TextPageController.flipPage),
                                           userInfo: nil,
                                           repeats: false)    // 次の自動めくりを予約する
            pos.setText("")
        }
    }
  
    // シャッフルして新しいQuoteを表示
    func reShuffle() {
        var dispText: String = ""
      
        if flashCardAnswer != "" {
            // 前回問題文だけを表示している場合、全文を表示
            dispText = flashCardAnswer
            flashCardAnswer = ""
        }
        else {
            // 前回は問題文を表示していない場合（全文表示か、そもそも暗記カードモードでない）
            flashCardAnswer = (bookInfo?.getShuffledParagraph())!
          
            // 文の途中に1個だけ','があって、最後が'.'でない時、暗記カードモードとする
            let comma = isFlashCardContents(str: flashCardAnswer)
            if comma != nil {
                dispText = flashCardAnswer.substring(to: comma!)
            }
            else {
                // 暗記カードモードではない、そのまま全文表示
                dispText = flashCardAnswer
                flashCardAnswer = ""
            }
        }

        displayText(dispText + "\n\n")
        pos.setText("(shuffled quote)")
    }
    func isFlashCardContents(str: String) -> String.Index? {
        // 文の途中に1個だけ','があって、最後が'.'でない時、暗記カードモードとする
        var count = 0
        var nextRange = str.startIndex..<str.endIndex //最初は文字列全体から探す
        while let range = str.range(of: ",", options: .caseInsensitive, range: nextRange) {
            count += 1
            nextRange = range.upperBound..<str.endIndex //見つけた単語の次(range.upperBound)から元の文字列の最後までの範囲で次を探す
        }
        if count == 1 {
            let range = str.range(of: ",", options: .caseInsensitive, range: str.startIndex..<str.endIndex)
            return range!.lowerBound
        }
        else {
            return nil
        }
    }
    // 空コンテンツの表示
    func setEmptyContent() {
        displayText("Library is empty.\n\nPlease Sync some text files from iPhone.")
        pos.setText("")
    }
  
    // テキストをテーブルに更新して、表示を最上部にスクロール
    func displayText(_ disptext: String) {
        if cacheText != disptext {
            table.setNumberOfRows(1, withRowType: "FileTableRow")  //OSのバグ？スクロール位置がずれるのでWorkaround
        }
        let row = table.rowController(at: 0) as! FilesTableRow
        row.contentLabel.setText(disptext)
      
        if cacheText != disptext {
            // ページ先頭にスクロール
            //table.scrollToRow(at: -1)
            cacheText = disptext
            
            //SpeechSynthesizerをリフレッシュ
            let (speechShow, _, _) = SettingsUtility.getSpeechSettings()
            if nowSpeeching && speechShow {
                SpeechSynthManager.sharedManager.restartSpeechText(start: nowSpeeching)
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                    MPMediaItemPropertyTitle: bookInfo!.filename,
                    MPMediaItemPropertyArtist : "mameTxt"
                ]
            }
        }
    }
  
    // テキスト本文部分はtableになってて、押すと改ページする
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if bookInfo == nil {
            return
        }
        
        switch bookInfo!.getViewMode() {
        case bookInfo!.SHUFFLEMODE:
            reShuffle()
        case bookInfo!.AUTOFLIPMODE:
            if timer != nil {
                stopFlipTimer()   // 自動めくりモードをいったんポーズする
            } else {
                flipPage()      // もう一回押すとタイマー再開する
            }
        default:
            _ = bookInfo!.openNextPage()
            jumpToBookmarkPage()
        }
    }
  
    // スワイプ操作をすると1ページ前/後をめくって戻れる
    @IBAction func swipeRight(_ sender: AnyObject) {
        if bookInfo == nil {
            return
        }
        
        switch bookInfo!.getViewMode() {
        case bookInfo!.SHUFFLEMODE:
            reShuffle()
        case bookInfo!.AUTOFLIPMODE:
            if autoFlipPointer <= (maxflippagelen_forcecut + 1) {  // 先頭めくりページなら前のページの先頭に戻る
                bookInfo!.openPreviousPage()
            }
            jumpToBookmarkPage()
        default:
            bookInfo!.openPreviousPage()
            jumpToBookmarkPage()
        }
    }
    // 特に後のページをめくるのはAutoFlip時に有効なUI
    @IBAction func swipeLeft(_ sender: AnyObject) {
        if bookInfo == nil {
            return
        }
        
        switch bookInfo!.getViewMode() {
        case bookInfo!.SHUFFLEMODE:
            reShuffle()
        default:  //AutoFlipでもNormalでも同じく次のページの先頭に進む
            _ = bookInfo!.openNextPage()
            jumpToBookmarkPage()
        }
    }
  
    // 各種ダイアログの呼び出し
    @IBAction func pushPageJump() {   // ページジャンプダイアログを開く
        let context: AnyObject = self
        self.presentController(withName: "PageJumpController", context: context)
    }
    @IBAction func pushDictionaryOpen() {   // 辞書ダイアログを開く
        let context: AnyObject = self
        self.presentController(withName: "DictionaryController", context: context)
    }
    @IBAction func openAnotherTextFile() {    // ファイル選択ダイアログを開く
        stopReading()
        let context: AnyObject = self
        self.presentController(withName: "FileListController", context: context)
    }
    @IBAction func openSettings() {   // ファイル選択ダイアログを開く
        stopReading()
        let context: AnyObject = self
        self.presentController(withName: "SettingsController", context: context)
    }
  
    func stopReading() {
        if nowSpeeching {
            nowSpeeching = false
            SpeechSynthManager.sharedManager.restartSpeechText(start: false)
        }
        resetSpeechButtonDisplay()
    }

    // ページジャンプダイアログで指定のページに飛ぶ
    func jumpDidFinish(_ context:Float){
        bookInfo?.bookmark = Int(context)
        dismiss()
      
        // Normal modeに戻しておく
        self.bookInfo!.shufflemode = self.bookInfo!.NORMALMODE
    }
  
    func deleteBook(_ context:Bool) {
        dismiss()

        let defaultAction = WKAlertAction(
            title: "Cancel",
            style: WKAlertActionStyle.default) { () -> Void in
        }
        let destructiveAction = WKAlertAction(
            title: "Erase",
            style: WKAlertActionStyle.destructive) { () -> Void in

            // メッセージ確認の上、ファイルを消してファイルリストを開く
            self.bookManager.eraseOneBook((self.bookInfo?.filename)!)
            if self.bookManager.getFileCount() > 0 {
                // まだファイルが残ってれば、ファイルリストを開く
                self.openAnotherTextFile()
                // ファイル数がゼロなら、この画面で「何かSyncして」というメッセージを出してる方がいい
            }
        }

        // アラートメッセージ表示
        let actions = [defaultAction, destructiveAction]
        self.presentAlert(
            withTitle: "",
            message: "Erase This File?",
            preferredStyle: .alert,
            actions: actions)

    }
  
    // コンテキストメニューの表示
    func setNormalViewMenu() {        // Normal Mode用のPress Menu追加
        clearAllMenuItems()   //クリアしてから
        addMenuItem(with: UIImage(named:"openMenuIcon")!, title: "OpenFile", action: #selector(TextPageController.openAnotherTextFile))
        addMenuItem(with: UIImage(named:"dictMenuIcon")!, title: "Dictionary", action: #selector(TextPageController.pushDictionaryOpen))
        addMenuItem(with: UIImage(named:"jumpMenuIcon")!, title: "PageJump", action: #selector(TextPageController.pushPageJump))
        addMenuItem(with: UIImage(named:"settingsIcon")!, title: "Settings", action: #selector(TextPageController.openSettings))
    }
    func setShuffleViewMenu() {        // Shuffle Mode用のPress Menu追加
        clearAllMenuItems()   //クリアしてから
        addMenuItem(with: UIImage(named:"openMenuIcon")!, title: "OpenFile", action: #selector(TextPageController.openAnotherTextFile))
        addMenuItem(with: UIImage(named:"dictMenuIcon")!, title: "Dictionary", action: #selector(TextPageController.pushDictionaryOpen))
        addMenuItem(with: UIImage(named:"settingsIcon")!, title: "Settings", action: #selector(TextPageController.openSettings))
    }

    @objc func togglePlayPause(event: MPRemoteCommandEvent) {
        SpeechSynthManager.sharedManager.togglePlayPause()
    }
    @objc func continuePlay(event: MPRemoteCommandEvent) {
        SpeechSynthManager.sharedManager.continuePlay()
    }
    @objc func pausePlay(event: MPRemoteCommandEvent) {
        SpeechSynthManager.sharedManager.pausePlay()
    }
    @objc func skipForward(event: MPRemoteCommandEvent) {
        _ = bookInfo!.openNextPage()
        jumpToBookmarkPage()
    }
    @objc func skipBackward(event: MPRemoteCommandEvent) {
        bookInfo!.openPreviousPage()
        jumpToBookmarkPage()
    }
    
    // タイマーSTOP
    func stopFlipTimer() {
        timer?.invalidate()
        timer = nil
    }
  
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
      
        stopFlipTimer()
        BookDBUtility.saveTocController(bookManager.toctable, syncnow: true)
    }
  
}
