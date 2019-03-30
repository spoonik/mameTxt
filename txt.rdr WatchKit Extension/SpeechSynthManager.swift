//
//  SpeechSynthManager.swift
//  txt.rdr WatchKit Extension
//
//  Created by spoonik on 2018/11/03.
//  Copyright © 2018 spoonikapps. All rights reserved.
//

import WatchKit
import AVFoundation

protocol SpeechSynthManagerAutoPageFlipDelegate {
    func callbackNextPage(terminated: Bool)
}

class SpeechSynthManager: NSObject, AVSpeechSynthesizerDelegate {
    var audioSettingDone = false
    let session = AVAudioSession.sharedInstance()
    var talker = AVSpeechSynthesizer()
    var delegate: SpeechSynthManagerAutoPageFlipDelegate? = nil
    
    var bookInfo: BookInfo? = nil
    static let sharedManager: SpeechSynthManager = {
        let instance = SpeechSynthManager()
        return instance
    }()

    fileprivate override init() {
    }
    
    func setDelegate(delegate: SpeechSynthManagerAutoPageFlipDelegate) {
        self.delegate = delegate
    }
    func restartSpeechText(start: Bool?) {
        var temp_start: Bool = false
        if start == nil {
            temp_start = self.talker.isSpeaking
        } else {
            temp_start = start!
        }
        self.talker.delegate = self
        bookInfo = BookManager.sharedManager.getOpenedBook()
        
        if !setupAudioSessions(on: true) {
            return
        }
        
        self.talker.stopSpeaking(at: AVSpeechBoundary.immediate)
        if !temp_start {
            return
        }
        
        if bookInfo == nil {
            // 停止しているか、本がないか
            return
        }
        
        let content = bookInfo!.getCurrentPageContent()
        let speechSpeed = bookInfo!.getReadingSpeed()
        let lang = bookInfo!.getContentLanguage()
        
        // Activate and request the route.
        let utterance = AVSpeechUtterance(string: content)
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        utterance.rate = speechSpeed
        self.talker.speak(utterance)
        //let sound = Bundle.main.path(forResource: "silent", ofType: "m4a")
        //let audioPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        //audioPlayer!.play()
    }
    
    func togglePlayPause() {
        if self.talker.isSpeaking {
            self.talker.pauseSpeaking(at: .immediate)
        } else {
            self.talker.continueSpeaking()
        }
    }
    func continuePlay() {
        self.talker.continueSpeaking()
    }
    func pausePlay() {
        self.talker.pauseSpeaking(at: .immediate)
    }
    func skipForward() {
        bookInfo = BookManager.sharedManager.getOpenedBook()
        if !bookInfo!.openNextPage() {
            if self.delegate != nil {
                delegate!.callbackNextPage(terminated: false)
            }
        }
    }
    func skipBackward() {
        bookInfo = BookManager.sharedManager.getOpenedBook()
        bookInfo!.openPreviousPage()
        if self.delegate != nil {
            delegate!.callbackNextPage(terminated: false)
        }
    }
    
    // 現在のページを読み終わった時に呼ばれるコールバック：次のページをめくって読み始める
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        bookInfo = BookManager.sharedManager.getOpenedBook()
        var terminated = false
        if !bookInfo!.openNextPage() {
            restartSpeechText(start: false)
            terminated = true
        }
        BookDBUtility.saveTocController(BookManager.sharedManager.toctable, syncnow: true)
        if self.delegate != nil {
            delegate!.callbackNextPage(terminated: terminated)
        } else {
            restartSpeechText(start: true)
        }
    }
    func setupAudioSessions(on: Bool) -> Bool {
        //if audioSettingDone == on {
        //return true
        //}
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback,
                                    mode: AVAudioSessionModeDefault,
                                    routeSharingPolicy: AVAudioSession.RouteSharingPolicy.longForm)
            //,options: .duckOthers)
            session.activate(options: [], completionHandler: callbk)
            try session.setActive(on)
        } catch let error {
            print("*** Unable to set up the audio session: \(error.localizedDescription) ***")
            audioSettingDone = false
            return false
        }
        audioSettingDone = on
        return true
    }
    
    func callbk(suc: Bool, err: Error?) -> Void {
        // AudioSession呼び出しのためのダミーのコールバック
    }
}
