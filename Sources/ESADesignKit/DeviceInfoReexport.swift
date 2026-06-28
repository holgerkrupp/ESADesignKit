//
//  DeviceInfoReexport.swift
//  ESADesignKit
//
//  ESADesignKit owns the DeviceInfo dependency and re-exports it, so any app that
//  imports ESADesignKit automatically gets DeviceInfo's helpers
//  (`\.deviceUIStyle`, `.withDeviceStyle()`, `DeviceUIStyle`, `DeviceDetector`)
//  without referencing the DeviceInfo package itself.
//

@_exported import DeviceInfo
