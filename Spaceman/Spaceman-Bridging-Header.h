//
//  Spaceman-Bridging-Header.h
//  Spaceman
//
//  Created by Sasindu Jayasinghe on 23/11/20.
//

#ifndef Spaceman_Bridging_Header_h
#define Spaceman_Bridging_Header_h

#import <Foundation/Foundation.h>

// Private CoreGraphics SPI. Undocumented, not App-Store-safe, and subject
// to break across macOS releases. Only declare the symbols we actually
// consume so the private-API surface is minimal and auditable.

int _CGSDefaultConnection(void);
id CGSCopyManagedDisplaySpaces(int conn);

#endif /* Spaceman_Bridging_Header_h */
