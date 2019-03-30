//
//  ComplicationController.swift
//  watchOS2Sampler WatchKit Extension
//
//  Created by Shuichi Tsutsumi on 2015/06/10.
//  Copyright © 2015年 Shuichi Tsutsumi. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    var bookManager = BookManager.sharedManager

    public func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(nil)
        
    }

    
    // MARK: - Timeline Configuration
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
  
    private func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: @escaping (NSDate?) -> Void) {
        handler(nil)
    }
    
    private func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
  
    private func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
/*        var nextDate = NSDate(timeIntervalSinceNow: 1 * 60 * 60)
        var timeLineEntryArray = [CLKComplicationTimelineEntry]()
        for _ in 1...3 {
            let entry : CLKComplicationTimelineEntry? = createTimeLineEntry(complication: complication, date: nextDate)
            timeLineEntryArray.append(entry!)
            nextDate = nextDate.addingTimeInterval(1 * 60 * 60)
        }*/

        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    private func getNextRequestedUpdateDateWithHandler(handler: @escaping (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(nil);
    }
  
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
  
    func getTimeLineEntry(forPlaceholder: Bool) -> (String, Float) {
        let bookManager = BookManager.sharedManager
        var bookInitial = bookManager.getBookInitial()
        var bookProgress = bookManager.getBookProgress()
        if forPlaceholder {
            bookInitial = "mT"
            bookProgress = 0.7
        }
        return (bookInitial, bookProgress)
    }

    func createTimeLineTemplate(complication: CLKComplication, date: NSDate, placeholder: Bool) -> CLKComplicationTemplate? {

        var bookInitial: String
        var bookProgress: Float
        (bookInitial, bookProgress) = getTimeLineEntry(forPlaceholder: true)

        switch complication.family {
        case .utilitarianSmall:
            let stemplate = CLKComplicationTemplateUtilitarianSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return stemplate
        case .modularSmall:
            let stemplate = CLKComplicationTemplateModularSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return stemplate
        case .circularSmall:
            let stemplate = CLKComplicationTemplateCircularSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return stemplate
        default:
            return nil
        }
    }
    func createTimeLineEntry(complication: CLKComplication, date: NSDate) -> CLKComplicationTimelineEntry {

        var bookInitial: String
        var bookProgress: Float
        (bookInitial, bookProgress) = getTimeLineEntry(forPlaceholder: true)

        switch complication.family {
        case .utilitarianSmall:
            let stemplate = CLKComplicationTemplateUtilitarianSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return CLKComplicationTimelineEntry(date: date as Date, complicationTemplate: stemplate)
        case .modularSmall:
            let stemplate = CLKComplicationTemplateModularSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return CLKComplicationTimelineEntry(date: date as Date, complicationTemplate: stemplate)
        case .circularSmall:
            let stemplate = CLKComplicationTemplateCircularSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return CLKComplicationTimelineEntry(date: date as Date, complicationTemplate: stemplate)
        default:
            let stemplate = CLKComplicationTemplateCircularSmallRingText()
            stemplate.textProvider = CLKSimpleTextProvider(text: bookInitial)
            stemplate.fillFraction = bookProgress
            return CLKComplicationTimelineEntry(date: date as Date, complicationTemplate: stemplate)
        }

    }

 
}

