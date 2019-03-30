//
//  DictionaryController.swift
//  txt.rdr WatchKit Extension
//
//  Created by spoonik on 2018/06/08.
//  Copyright © 2018年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation


class DictionaryController: WKInterfaceController, QueryEndDelegate {
    func queryFinish(str: String) {
        define_label.setText(str)
    }
  
    let query_uri_base = "https://www.online-utility.org/english/dictionary.jsp?word="
    let query_regex = "</h4>.*?<p/>"
  
    var word_list: [String] = []
    var current_word = ""
    var delegate:PageJumpControllerDelegate! = nil
    var isWiFiConnection: Bool = true
    @IBOutlet var define_label: WKInterfaceLabel!
    @IBOutlet var word_picker: WKInterfacePicker!
    @IBOutlet var url_label: WKInterfaceLabel!
    @IBOutlet var define_button: WKInterfaceButton!
  
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        let pageController: TextPageController = (context as? TextPageController)!
        word_list = separateStringToWords(content: pageController.content)
        /*
        if word_list.count == 0 {
            let defaultAction = WKAlertAction(
                title: "OK",
                style: WKAlertActionStyle.default) { () -> Void in
            }

            // アラートメッセージ表示
            let actions = [defaultAction]
            self.presentAlert(
                withTitle: "",
                message: "No Word Found",
                preferredStyle: .alert,
                actions: actions)
          
            return
        }
        */
        
        if word_list.count > 0 {
            current_word = word_list[0]
        }
        delegate = pageController
        setWordsPicker(words: word_list)
        setSupportedURL(site: self.query_uri_base)
    }
  
    func setSupportedURL(site: String) {
        let url = URL(string: site)
        url_label.setText((url?.host)!)
    }
  
    func setWordsPicker(words: [String]) {
        var pickerItems: [WKPickerItem]! = []
        for word in words {
            let pickerItem = WKPickerItem()
            pickerItem.title = word
            pickerItems.append(pickerItem)
        }
        word_picker.setItems(pickerItems)
        word_picker.focus()
    }
  
    func separateStringToWords(content: String) -> [String] {
        var word_map = getMatchStrings(targetString: content, pattern: "[A-Za-z]+")
        if word_map.count == 0 {
            return []
        }
        // アルファベット順にソートする（大文字小文字混ざって）
        word_map = word_map.sorted(by: { $0.lowercased() < $1.lowercased() })
        // 4文字以下の単語を削除する
        var filtered_word_map: [String] = []
        for word in word_map {
            if word.count > 4 {
                filtered_word_map.append(word)
            }
        }
      
        // ダブりを削除する
        let orderedSet = NSOrderedSet(array: filtered_word_map)
        let uniqueValues = orderedSet.array as! [String]

        return uniqueValues
    }
  
    func getMatchStrings(targetString: String, pattern: String) -> [String] {
        var matchStrings:[String] = []

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let targetStringRange = NSRange(location: 0, length: (targetString as NSString).length)
          
            let matches = regex.matches(in: targetString, options: [], range: targetStringRange)
          
            for match in matches {
                // rangeAtIndexに0を渡すとマッチ全体が、1以降を渡すと括弧でグループにした部分マッチが返される
              let range = match.range(at: 0)
                let result = (targetString as NSString).substring(with: range)
                matchStrings.append(result)
            }
            return matchStrings
        } catch {
            print("error: getMatchStrings")
        }
        return []
    }

    @IBAction func selectWordPicker(_ value: Int) {
        current_word = word_list[value]
        print(current_word)
    }
    
    @IBAction func pushDefineQuery() {
        let query_uri = query_uri_base + current_word
        let q = Query(query_address: query_uri,
                      scrape_regex: query_regex,
                      controller: self)
        q.query_and_scrape()
      
        word_picker.resignFocus()
    }
  
  
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
      
        if isWiFiConnection == false {
            word_picker.setHidden(true)
            define_button.setHidden(true)
            define_label.setText("No Internet Connection")
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

