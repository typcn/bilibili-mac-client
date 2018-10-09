//
//  TimeSilderCell.swift
//  bilibili
//
//  Created by xjbeta on 2016/12/2.
//  Copyright © 2016年 TYPCN. All rights reserved.
//

import Cocoa

class TimeSliderCell: NSSliderCell {
	override func drawKnob(_ knobRect: NSRect) {
		NSColor.white.setFill()
		NSRectFill(knobRect)
	}
	override func knobRect(flipped: Bool) -> NSRect {
		let knobWidth: CGFloat = 3
		let knobHeight: CGFloat = 12
		let width = barRect(flipped: true).size.width
		var x: CGFloat = CGFloat(doubleValue / maxValue) * width - knobWidth / 2
		let y: CGFloat = (15 - knobHeight) / 2
		if x < 0 {
			x = 0
		} else if x > width - knobWidth {
			x = width - knobWidth
		}
		return NSRect(x: x, y: y, width: knobWidth, height: knobHeight)
	}
}
