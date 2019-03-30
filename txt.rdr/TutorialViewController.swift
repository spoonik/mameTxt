//
//  TutorialViewController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/06/25.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    @IBOutlet weak var imageVIew: UIImageView!
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pushOne(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pushOne(_ sender: AnyObject) {
        imageVIew.image = UIImage(named: "tutorial1.png")
    }

    @IBAction func pushTwo(_ sender: AnyObject) {
        imageVIew.image = UIImage(named: "tutorial2.png")
    }

    @IBAction func pushThree(_ sender: AnyObject) {
        imageVIew.image = UIImage(named: "tutorial3.png")
    }

    @IBAction func pushFour(_ sender: AnyObject) {
        imageVIew.image = UIImage(named: "tutorial4.png")
    }

    @IBAction func pushFive(_ sender: AnyObject) {
        imageVIew.image = UIImage(named: "tutorial5.png")
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
