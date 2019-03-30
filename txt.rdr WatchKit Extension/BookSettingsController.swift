//
//  BookSettingsController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/11/13.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation


protocol BookDeleteDelegate {
    func deleteBook(_ context:Bool)
}

// 読み上げスピードの上限下限セット：OSの特性で、聞ける領域は狭い
let minVoiceOverSpeed: Float = 4.0
let maxVoiceOverSpeed: Float = 7.0


class BookSettingsController: WKInterfaceController {

    @IBOutlet var shuffleSwitch: WKInterfaceSwitch!
    @IBOutlet var flipSpeedSlider: WKInterfaceSlider!
  
    var delegate: TextPageController! = nil
    
    var speechSwitch: Bool = true
    var speechSpeed: Float = 0.5
    var lang: String = Locale.preferredLanguages[0]
    @IBOutlet var speechSwitchButton: WKInterfaceSwitch!
    @IBOutlet var speechSpeedSlider: WKInterfaceSlider!
    @IBOutlet weak var speechVolumeSlider: WKInterfaceSlider!
    @IBOutlet weak var voiceOverGroup: WKInterfaceGroup!
    @IBOutlet weak var autoFlipGroup: WKInterfaceGroup!
    
    
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    @IBAction func setSpeechMode(_ value: Bool) {
        speechSwitch = value
        voiceOverGroup.setHidden(!speechSwitch)
        //autoFlipGroup.setHidden(speechSwitch)
    }
    @IBAction func pushLanguageSelectButton() {
        let action1 = WKAlertAction(
            title: Locale.preferredLanguages[0],
            style: WKAlertActionStyle.default) { () -> Void in
                self.lang = Locale.preferredLanguages[0]
        }
        let action2 = WKAlertAction(
            title: "en-US",
            style: WKAlertActionStyle.default) { () -> Void in
                self.lang = "en-US"
        }
        let action3 = WKAlertAction(
            title: "fr-FR",
            style: WKAlertActionStyle.default) { () -> Void in
                self.lang = "fr-FR"
        }
        let action4 = WKAlertAction(
            title: "es-ES",
            style: WKAlertActionStyle.default) { () -> Void in
                self.lang = "es-ES"
        }
        
        // アラートメッセージ表示
        let actions = [action1, action2, action3, action4]
        self.presentAlert(
            withTitle: "",
            message: "VoiceOver Language",
            preferredStyle: .actionSheet,
            actions: actions)
        
    }
    @IBAction func changeSpeechSpeed(_ value: Float) {
        speechSpeed = convertValueToSpeechSpeed(value: value)
    }
    @IBAction func changeSpeechVolume(_ value: Float) {
        //SpeechSynthManager.sharedManager.session.outputVolume = value
    }
    func convertValueToSpeechSpeed(value: Float) -> Float { // valueの前提: 0.0-10.0
        return (minVoiceOverSpeed + (maxVoiceOverSpeed - minVoiceOverSpeed) * (value / 10.0)) / 10.0
    }
    func convertSpeechSpeedToValue(speed: Float) -> Float {
        return (minVoiceOverSpeed + (maxVoiceOverSpeed - minVoiceOverSpeed) * speed) * 10.0
    }

    
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    @IBAction func setShuffleMode(_ value: Bool) {
        BookManager.sharedManager.getOpenedBook()!.setShuffleMode(set: value)
        flipSpeedSlider.setEnabled(value==false)
    }

    @IBAction func setAutoFlipSpeed(_ value: Float) {
        BookManager.sharedManager.getOpenedBook()?.setAutoFlipSpeedIndex(speed: Int(value))
    }

    @IBAction func pushDeleteButton() {
        delegate.deleteBook(true)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        let pageController: TextPageController = (context as? TextPageController)!
        delegate = pageController
        let isShuffle = BookManager.sharedManager.getOpenedBook()!.isShuffleMode()
        shuffleSwitch.setOn(isShuffle)
        flipSpeedSlider.setValue( Float((BookManager.sharedManager.getOpenedBook()?.getAutoFlipSpeedIndex())!) )
        flipSpeedSlider.setEnabled(isShuffle==false)

        (speechSwitch, speechSpeed, lang) = SettingsUtility.getSpeechSettings()
        lang = BookManager.sharedManager.getOpenedBook()!.lang
        speechSpeed = BookManager.sharedManager.getOpenedBook()!.reading_speed
        speechSwitchButton.setOn(speechSwitch)
        speechSpeedSlider.setValue(speechSpeed * 10.0)
        speechVolumeSlider.setValue(SpeechSynthManager.sharedManager.session.outputVolume)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    override func willDisappear() {
        SettingsUtility.setSpeechSettings(speechSwitch: speechSwitch, speed: speechSpeed, language: lang)
        BookManager.sharedManager.getOpenedBook()!.setContentLanguage(newlang: lang)
        BookManager.sharedManager.getOpenedBook()!.setReadingSpeed(speed: speechSpeed)
    }
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
