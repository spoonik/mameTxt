//
//  SpeechInterfaceController.swift
//  txt.rdr WatchKit Extension
//
//  Created by spoonik on 2018/11/03.
//  Copyright © 2018 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation


class SpeechInterfaceController: WKInterfaceController {
    @IBOutlet var speechingBookName: WKInterfaceLabel!
    @IBOutlet var volumeControl: WKInterfaceVolumeControl!
    
    @IBOutlet weak var speedSlider: WKInterfaceSlider!
    @IBOutlet weak var startStopSpeech: WKInterfaceButton!
    
    var nowSpeeching = false
    
    var bookInfo: BookInfo? = nil
    var bookManager = BookManager.sharedManager

    // 読み上げスピードの上限下限セット：OSの特性で、聞ける領域は狭い
    let minSpeed: Float = 4.0
    let maxSpeed: Float = 7.0

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        bookInfo = bookManager.getOpenedBook()

        speechingBookName.setText(bookInfo == nil ? "No Book" : bookInfo!.filename)
        startStopSpeech.setEnabled(bookInfo != nil)
        speedSlider.setEnabled(bookInfo != nil)
        let (_, speechSpeed,_) = SettingsUtility.getSpeechSettings()
        speedSlider.setValue(convertSpeechSpeedToValue(speed: speechSpeed))
    }

    @IBAction func pushStartStopSpeech() {
        if bookInfo == nil {
            return
        }
        
        nowSpeeching = !nowSpeeching
        startStopSpeech.setBackgroundImageNamed(nowSpeeching ? "pause" : "play")
        //startStopSpeech.setTitle(nowSpeeching ? "Speeching" : "Start Speech")
        //startStopSpeech.setAlpha(nowSpeeching ? 1.0 : 0.5)

        SpeechSynthManager.sharedManager.restartSpeechText(start: nowSpeeching)
    }
    
    @IBAction func changeSpeedSlider(_ value: Float) {
        //let newSpeed = convertValueToSpeechSpeed(value: value)
        //SpeechSynthManager.sharedManager.restartSpeechText(start: nowSpeeching)
    }
    
    func convertValueToSpeechSpeed(value: Float) -> Float { // valueの前提: 0.0-10.0
        return (minSpeed + (maxSpeed - minSpeed) * (value / 10.0)) / 10.0
    }
    func convertSpeechSpeedToValue(speed: Float) -> Float {
        return (minSpeed + (maxSpeed - minSpeed) * speed) * 10.0
    }

    override func willActivate() {
        super.willActivate()
    }
    override func didDeactivate() {
        super.didDeactivate()
        //_ = setupAudioSessions(on: false)
    }
}


/*
class SpeechInterfaceController: WKInterfaceController, AVSpeechSynthesizerDelegate {
    @IBOutlet var speechingBookName: WKInterfaceLabel!
    @IBOutlet var volumeControl: WKInterfaceVolumeControl!
    
    @IBOutlet weak var speedSlider: WKInterfaceSlider!
    @IBOutlet weak var startStopSpeech: WKInterfaceButton!
    
    var nowSpeeching = false
    var audioSettingDone = false
    let session = AVAudioSession.sharedInstance()
    var talker = AVSpeechSynthesizer()  // Speech
    
    var bookInfo: BookInfo? = nil
    var bookManager = BookManager.sharedManager
    
    // 読み上げスピードの上限下限セット：OSの特性で、聞ける領域は狭い
    let minSpeed: Float = 4.0
    let maxSpeed: Float = 7.0
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        bookInfo = bookManager.getOpenedBook()
        self.talker.delegate = self
        
        speechingBookName.setText(bookInfo == nil ? "No Book" : bookInfo!.filename)
        startStopSpeech.setEnabled(bookInfo != nil)
        speedSlider.setEnabled(bookInfo != nil)
        let (_, speechSpeed) = SettingsUtility.getSpeechSettings()
        speedSlider.setValue(convertSpeechSpeedToValue(speed: speechSpeed))
    }
    
    @IBAction func pushStartStopSpeech() {
        if bookInfo == nil {
            return
        }
        
        nowSpeeching = !nowSpeeching
        startStopSpeech.setBackgroundImageNamed(nowSpeeching ? "pause" : "play")
        //startStopSpeech.setTitle(nowSpeeching ? "Speeching" : "Start Speech")
        //startStopSpeech.setAlpha(nowSpeeching ? 1.0 : 0.5)
        
        restartSpeechText()
    }
    
    @IBAction func changeSpeedSlider(_ value: Float) {
        let newSpeed = convertValueToSpeechSpeed(value: value)
        SettingsUtility.setSpeechSettings(speech: false, speed: newSpeed)
        restartSpeechText()
    }
    
    func convertValueToSpeechSpeed(value: Float) -> Float { // valueの前提: 0.0-10.0
        return (minSpeed + (maxSpeed - minSpeed) * (value / 10.0)) / 10.0
    }
    func convertSpeechSpeedToValue(speed: Float) -> Float {
        return (minSpeed + (maxSpeed - minSpeed) * speed) * 10.0
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
            //try session.setActive(on)
        } catch let error {
            print("*** Unable to set up the audio session: \(error.localizedDescription) ***")
            audioSettingDone = false
            return false
        }
        audioSettingDone = on
        return true
    }
    
    func restartSpeechText() {
        if !setupAudioSessions(on: true) {
            return
        }
        
        self.talker.stopSpeaking(at: AVSpeechBoundary.immediate)
        
        if !nowSpeeching || bookInfo == nil {
            // 停止しているか、本がないか
            return
        }
        
        let content = bookInfo!.getCurrentPageContent()
        let lang = bookInfo!.getContentLanguage()
        
        let (_, speechSpeed) = SettingsUtility.getSpeechSettings()
        
        // Activate and request the route.
        let utterance = AVSpeechUtterance(string: content)
        utterance.voice = AVSpeechSynthesisVoice(language: lang)
        utterance.rate = speechSpeed
        self.talker.speak(utterance)
        //let sound = Bundle.main.path(forResource: "silent", ofType: "m4a")
        //let audioPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        //audioPlayer!.play()
    }
    
    // 現在のページを読み終わった時に呼ばれるコールバック：次のページをめくって読み始める
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        bookInfo!.openNextPage()
        restartSpeechText()
    }
    
    func callbk(suc: Bool, err: Error?) -> Void {
        // AudioSession呼び出しのためのダミーのコールバック
    }
    override func willActivate() {
        super.willActivate()
    }
    override func didDeactivate() {
        super.didDeactivate()
        //_ = setupAudioSessions(on: false)
    }
}
*/
