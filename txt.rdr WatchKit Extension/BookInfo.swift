//
//  BookInfo.swift
//  txt.rdr
//
//  Created by spoonik on 2016/04/16.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit

let linefeed: unichar = ("\n" as NSString).character(at: 0)
let period: unichar = ("." as NSString).character(at: 0)
let largeperiod: unichar = ("．" as NSString).character(at: 0)
let space: unichar = (" " as NSString).character(at: 0)
let jpperiod: unichar = ("。" as NSString).character(at: 0)
let jpdot: unichar = ("、" as NSString).character(at: 0)

let MAXSUPPORTFILESIZE: UInt64 = 20971520    //20MBのファイルまでしか扱えない
var MAXPAGELENGTH: Int = 600    // 1ページに含める文字数。1バイト換算で

let FLIPSPEEDS: [Double] = [0.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0]


class BookInfo {
    let docsDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
  
    var maxpagelen: Int
    var maxpagelen_forcecut: Int
  
    let AUTOFLIPMODE: Int = 3
    let SHUFFLEMODE: Int = 1
    let NORMALMODE: Int = 0
  
    var filename: String
    var filesize: UInt64
    var bookmark: Int
    var pagepos: Array<Int>
    var parapos: Array<Int>
  
    var shufflemode: Int
    var autoflipspeed: Int
    
    var lang: String = Locale.preferredLanguages[0]
    var reading_speed: Float = 0.5
  
    var fileContent: NSString = ""

    init() {
        filename = ""
        filesize = 0
        bookmark = 0
        pagepos = [0]
        shufflemode = NORMALMODE
        autoflipspeed = 0
        parapos = [0]
        maxpagelen = MAXPAGELENGTH
        maxpagelen_forcecut = maxpagelen * 5 / 4
    }
  
    init(filepath: String) {
        filename = getFilePathComponent(filepath)
        filesize = 0
        bookmark = 0
        pagepos = [0]
        shufflemode = NORMALMODE
        autoflipspeed = 0
        parapos = [0]
        maxpagelen = MAXPAGELENGTH
        maxpagelen_forcecut = maxpagelen * 5 / 4
      
        do {  // ファイルサイズを確認
            if let attr: NSDictionary = try FileManager.default.attributesOfItem(atPath: filepath) as NSDictionary? {
                filesize = attr.fileSize()
            }
            if filesize > MAXSUPPORTFILESIZE || filesize == 0 {
                return
            }
      
            // ファイルを文字列に展開
            openBook()
        }
        catch let error as NSError {
            print("Error file read: \(error.description)")
            return
        }
      
        // ページ区切り位置を計算して、TOC情報を生成
        var index = 0, lastpagepos = 0

        // 2バイトテキストかどうかのチェック: 文字数とファイルサイズの比でページ長を決める
        let maxpagelendb: Double = Double(fileContent.length) / Double(filesize)
        maxpagelen = Int( Double(MAXPAGELENGTH * 2) * maxpagelendb )
        maxpagelen_forcecut = maxpagelen * 5 / 4
        
        if maxpagelendb > 0.8 {
            lang = "en-US"
        }

        // 区切り文字を見つけてページ区切りを設定する
        for i in 0..<fileContent.length {
            let c = fileContent.character(at: i)
            if isDelimiter(c: c) {
                if (index - lastpagepos) > maxpagelen {
                    // キリのいいところでページを区切る
                    pagepos.append(index+1)
                    lastpagepos = index
                }
            }
            else if (index - lastpagepos) > maxpagelen_forcecut {
                // いい区切りがなくても、強制的に区切る
                pagepos.append(index+1)
                lastpagepos = index
            }

            index += 1
        }
      
    }
  
    // ブックを開いてStringに展開する
    func openBook() {
        do {
            fileContent = try NSString(contentsOfFile: docsDir + "/" + filename, encoding: String.Encoding.utf8.rawValue)
            parapos = getParagraphPos(fileContent)
        }
        catch let error as NSError {
            print("Error file read: \(error.description)")
        }
    }
  
    // ブックから、現在のページ番号のSubstringを取り出して返す
    func getCurrentPageContent() -> String {
        var lengthToRead = fileContent.length - pagepos[bookmark]
        if bookmark < pagepos.count-1 {
            lengthToRead = pagepos[bookmark+1] - pagepos[bookmark]
        }
      
        // 先頭の改行文字を削除 (改行直前の「。」などで改ページすることが多いため)
        var disptext: String = getRangedPageContent(pagepos[bookmark], len: lengthToRead)
        while disptext[disptext.index(disptext.startIndex, offsetBy: 0)] == "\n" {
            disptext = String(disptext.dropFirst())
        }
      
        return disptext
    }

    func setContentLanguage(newlang: String) {
        lang = newlang
    }
    func setReadingSpeed(speed: Float) {
        reading_speed = speed
    }
    func getReadingSpeed() -> Float {
        return reading_speed
    }
    func getContentLanguage() -> String {
        return lang
    }
    // ブックから、指定のインデックスの範囲のSubstringを取り出して返す
    func getRangedPageContent(_ start: Int, len: Int) -> String {
        return fileContent.substring(with: NSRange(location: start,length: len))
    }
  
    // シャッフルしたパラグラフ番号を決定する
    func getShuffledParagraph() -> String {
        var quote: String = ""
        var random: Int = 0
        var quotelen = 0
        var quotecut = false
        var trial = 0
      
        while quotelen <= 2 && trial < 100 {   // 改行だけのパラグラフは無視する
            random = Int(arc4random_uniform(UInt32(parapos.count-1)))
            quotelen = parapos[random+1]-parapos[random]-1
            trial += 1    // 改行だらけの特殊なテキストに対応する。適当にあきらめる
        }
      
        // 長すぎるパラグラフはちょん切る
        if quotelen > maxpagelen {
            quotelen = maxpagelen
            quotecut = true
        }
      
        quote = getRangedPageContent(parapos[random]+1, len: quotelen)

        if quotecut {
            quote += "..."    // ちょん切った時の省略記号
        }
      
        return quote
    }
  
    // Shuffleモードのトグル
    func toggleShuffleMode() -> Int {
        shufflemode = (shufflemode == NORMALMODE) ? SHUFFLEMODE : NORMALMODE
        return shufflemode
    }
    func setShuffleMode(set: Bool) {
        shufflemode = set ? SHUFFLEMODE : NORMALMODE
    }
    func isShuffleMode() -> Bool {
        return (shufflemode == SHUFFLEMODE)
    }
  
    func getViewMode() -> Int {
        if shufflemode == SHUFFLEMODE {
            return SHUFFLEMODE
        }
        else if autoflipspeed > 0 {
            return AUTOFLIPMODE
        }
        return NORMALMODE
    }
  
  
    // AutoFlipモードのスピード設定 (-1ならOFF)
    func setAutoFlipSpeedIndex(speed: Int) {
        autoflipspeed = speed
    }
    func getAutoFlipSpeed() -> Double {
        return FLIPSPEEDS[autoflipspeed]
    }
    func getAutoFlipSpeedIndex() -> Int {
        return autoflipspeed
    }
  
    // 何ページ中の何ページに居るかを文字列で返す
    func getCurrentPagePosition() -> String {
        return "\(bookmark)/\(pagepos.count)"
    }
  
    // 前後のページを開く：ブックマークを進めるだけ
    func openNextPage() -> Bool {
        if bookmark < pagepos.count-1 {
            bookmark += 1
            return true
        }
        return false
    }
    func openPreviousPage() {
        if bookmark > 0 {
            bookmark -= 1
        }
    }

    // ブックの情報が整合性が取れているかどうかのチェック
    func isValid() -> Bool {
        if filename.isEmpty
                || filesize <= 0
                || bookmark < 0 || bookmark >= pagepos.count
                || pagepos.count <= 0 {
            return false
        }
        return true
    }

}

func isDelimiter(c: unichar) -> Bool {
    if c == linefeed || c == period || c == jpperiod || c == jpdot || c == largeperiod || c == space {
        return true
    }
    return false
}

func getParagraphPos(_ content: NSString) -> Array<Int> {
    var paragcount = 0
    var pos: Array<Int> = []
  
    for i in 0..<content.length {
        let c = content.character(at: i)
        if c == linefeed {
            paragcount += 1
            pos.append(i)
        }
    }
    return pos
}
