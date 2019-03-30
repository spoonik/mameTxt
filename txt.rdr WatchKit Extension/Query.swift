//
//  Query.swift
//  QScraper WatchKit Extension
//
//  Created by spoonik on 2017/12/03.
//  Copyright © 2017年 spoonikapps. All rights reserved.
//

import Foundation

protocol QueryEndDelegate {
    func queryFinish(str:String)
}

class Query: NSObject {

    let query_address: String
    let scrape_regex: String
    var scraped: String = ""
    var remove_html_tag: Bool = true
    var delegate:DictionaryController! = nil
    var session: URLSession = URLSession.shared

    init(query_address: String, scrape_regex: String, controller: DictionaryController) {
        self.query_address = query_address //"https://www.oxfordlearnersdictionaries.com/definition/english/word"
        self.scrape_regex = scrape_regex //"<span class=\"def\" .*?</span>"
        self.remove_html_tag = true
        delegate = controller
    }

    func query_and_scrape() {
        guard let url = URL(string: self.query_address) else {
            self.delegate.queryFinish(str: "No Such Page")
            return
        }

        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 10.0
        session = URLSession(configuration: config)
        session.dataTask(with: url, completionHandler: {(data, response, error) in
            /*
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.delegate.queryFinish(str: "No Internet Connection")
                }
            }
            */
            if let str = String(data: data!, encoding: String.Encoding.utf8) {
                let content = self.scrape(str: str, remove_html_tag: self.remove_html_tag)
                self.scraped = content
                self.delegate.queryFinish(str: self.scraped)
            } else {
                self.delegate.queryFinish(str: "Get URL Error")
            }
        }).resume()

        return
    }
  
    func scrape(str: String?, remove_html_tag: Bool) -> String {
        var formatted_result: String = ""
      
        if str != nil {
            let res = getMatchStrings(targetString: str!, pattern: self.scrape_regex)
            //let res = get_regex_matches(pattern:self.scrape_regex, str:str!)

            var define_str = ""
            for define in res {
                if remove_html_tag {
                    // <br>は改行に置換する
                    let one_define = define.replacingOccurrences(of:"<br/>", with:"\n\n")
                    //HTMLタグを削除する
                    define_str = one_define.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
                }
                else {
                    define_str = define
                }

                formatted_result += "\n"
                formatted_result += define_str
                formatted_result += "\n\n"
            }

            if res.count == 0 {
                // タグが見つからない
                formatted_result += "Word Not Found"
            }
        }
        else {
            // そもそもURLがみつからない
            formatted_result += "Page Not Found"
        }

        return formatted_result
    }
  
    func get_regex_matches(pattern: String, str: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      
        let matches = regex.matches(in: str, options: [], range: NSMakeRange(0, str.count))
        let res = matches.map { String(str[Range($0.range, in: str)!]) }

        print(res)
        return res
    }
  
    // 正規表現にマッチした文字列を格納した配列を返す
    func getMatchStrings(targetString: String, pattern: String) -> [String] {
     
        let targetString2 = targetString.replacingOccurrences(of:"\n", with:" ")
        var matchStrings:[String] = []
      
        do {
          
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let targetStringRange = NSRange(location: 0, length: (targetString2 as NSString).length)
          
            let matches = regex.matches(in: targetString2, options: [], range: targetStringRange)
          
            for match in matches {
              
                // rangeAtIndexに0を渡すとマッチ全体が、1以降を渡すと括弧でグループにした部分マッチが返される
                let range = match.range(at: 0)
                let result = (targetString2 as NSString).substring(with: range)
              
                matchStrings.append(result)
            }
          
            return matchStrings
          
        } catch {
            print("error: getMatchStrings")
        }
        return []
    }
}
extension Data
{
    func toString() -> String
    {
        return String(data: self, encoding: .utf8)!
    }
}
