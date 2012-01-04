/*
 *  key_coder.m
 *  KeyCoder
 *
 *  Created by Mark Rada on 11-07-27.
 *  Copyright 2011-2012 Marketcircle Incorporated. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>
#include "ruby/ruby.h"

static UCKeyboardLayout* keyboardLayout;

/**
 *
 *
 * @param [Fixnum]
 * @return [String]
 */
VALUE mAX_keycode_for(VALUE keyCode) {

  static UInt32       deadKeyState = 0;
  static UniCharCount actualStringLength = 0;
  static UniChar      string[255];

  UCKeyTranslate(
                 keyboardLayout,
                 keyCode,
                 kUCKeyActionDown,
                 0,
                 LMGetKbdType(), // kb type
                 0, // OptionBits keyTranslateOptions,
                 &deadKeyState,
                 255,
                 &actualStringLength,
                 string
                 );

  return (VALUE)[NSString stringWithCharacters:string length:255];

}

void Init_key_coder() {
  TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
  CFDataRef keyboardLayoutData      = (CFDataRef)TISGetInputSourceProperty(currentKeyboard,
                                                                           kTISPropertyUnicodeKeyLayoutData);
  keyboardLayout = (UCKeyboardLayout*)CFDataGetBytePtr(keyboardLayoutData);

  rb_define_private_method(rb_define_module("AX"), "keycode_for", mAX_keycode_for, 1);
}
