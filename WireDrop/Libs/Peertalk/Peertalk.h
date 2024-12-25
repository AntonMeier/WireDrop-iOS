//
//  Peertalk.h
//  rsms/peertalk
//

/// Note by Anton: I forked https://github.com/rsms/peertalk at some point in early/mid 2020, and have made a number of improvements to it since.
/// It will likely be a bit time consuming to get it up-to-date with the current version of rsms/peertalk, should there ever be a need to.

#import <Foundation/Foundation.h>

//! Project version number for Peertalk.
FOUNDATION_EXPORT double PeertalkVersionNumber;

//! Project version string for Peertalk.
FOUNDATION_EXPORT const unsigned char PeertalkVersionString[];

#import <Peertalk/PTChannel.h>
#import <Peertalk/PTProtocol.h>
#import <Peertalk/PTUSBHub.h>
