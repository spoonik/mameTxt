//
//  ComplicationTemplate.swift
//  txt.rdr
//
//  Created by spoonik on 2016/12/10.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit

class ComplicationTemplate: CLKComplicationTemplate {
    let modularLage = CLKComplicationTemplateModularLargeStandardBody()
    modularLage.headerTextProvider = CLKSimpleTextProvider(text: "Long Text")
    modularLage.body1TextProvider = CLKSimpleTextProvider(text: "Body Text 1")
    modularLage.body2TextProvider = CLKSimpleTextProvider(text: "Body Text 2")
    modularLage.headerImageProvider = CLKImageProvider(backgroundImage: UIImage(named: "image"), backgroundColor: nil)
}
