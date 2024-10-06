// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

<<<<<<< HEAD
=======
import '../base/error_handling_io.dart';
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';
import '../device.dart';
import '../macos/xcode.dart';

/// A wrapper around the `devicectl` command line tool.
///
/// CoreDevice is a device connectivity stack introduced in Xcode 15. Devices
/// with iOS 17 or greater are CoreDevices.
///
/// `devicectl` (CoreDevice Device Control) is an Xcode CLI tool used for
/// interacting with CoreDevices.
class IOSCoreDeviceControl {
  IOSCoreDeviceControl({
    required Logger logger,
    required ProcessManager processManager,
    required Xcode xcode,
    required FileSystem fileSystem,
  })  : _logger = logger,
        _processUtils = ProcessUtils(logger: logger, processManager: processManager),
        _xcode = xcode,
        _fileSystem = fileSystem;

  final Logger _logger;
  final ProcessUtils _processUtils;
  final Xcode _xcode;
  final FileSystem _fileSystem;

  /// When the `--timeout` flag is used with `devicectl`, it must be at
  /// least 5 seconds. If lower than 5 seconds, `devicectl` will error and not
  /// run the command.
  static const int _minimumTimeoutInSeconds = 5;

  /// Executes `devicectl` command to get list of devices. The command will
  /// likely complete before [timeout] is reached. If [timeout] is reached,
  /// the command will be stopped as a failure.
  Future<List<Object?>> _listCoreDevices({
    Duration timeout = const Duration(seconds: _minimumTimeoutInSeconds),
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return <Object?>[];
    }

    // Default to minimum timeout if needed to prevent error.
    Duration validTimeout = timeout;
    if (timeout.inSeconds < _minimumTimeoutInSeconds) {
      _logger.printError(
          'Timeout of ${timeout.inSeconds} seconds is below the minimum timeout value '
          'for devicectl. Changing the timeout to the minimum value of $_minimumTimeoutInSeconds.');
      validTimeout = const Duration(seconds: _minimumTimeoutInSeconds);
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('core_device_list.json');
    output.createSync();

    final List<String> command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'list',
      'devices',
      '--timeout',
      validTimeout.inSeconds.toString(),
      '--json-output',
      output.path,
    ];

    try {
<<<<<<< HEAD
      await _processUtils.run(command, throwOnError: true);

=======
      final RunResult result = await _processUtils.run(command, throwOnError: true);

      if (!output.existsSync()) {
        _logger.printError('After running the command ${command.join(' ')} the file');
        _logger.printError('${output.path} was expected to exist, but it did not.');
        _logger.printError('The process exited with code ${result.exitCode} and');
        _logger.printError('Stdout:\n\n${result.stdout.trim()}\n');
        _logger.printError('Stderr:\n\n${result.stderr.trim()}');
        throw StateError('Expected the file ${output.path} to exist but it did not');
      }
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
      final String stringOutput = output.readAsStringSync();
      _logger.printTrace(stringOutput);

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['result'];
        if (decodeResult is Map<String, Object?>) {
          final Object? decodeDevices = decodeResult['devices'];
          if (decodeDevices is List<Object?>) {
            return decodeDevices;
          }
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return <Object?>[];
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return <Object?>[];
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return <Object?>[];
    } finally {
<<<<<<< HEAD
      tempDirectory.deleteSync(recursive: true);
=======
      ErrorHandlingFileSystem.deleteIfExists(tempDirectory, recursive: true);
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
    }
  }

  Future<List<IOSCoreDevice>> getCoreDevices({
    Duration timeout = const Duration(seconds: _minimumTimeoutInSeconds),
  }) async {
<<<<<<< HEAD
    final List<IOSCoreDevice> devices = <IOSCoreDevice>[];

    final List<Object?> devicesSection = await _listCoreDevices(timeout: timeout);
    for (final Object? deviceObject in devicesSection) {
      if (deviceObject is Map<String, Object?>) {
        devices.add(IOSCoreDevice.fromBetaJson(deviceObject, logger: _logger));
      }
    }
    return devices;
=======
    final List<Object?> devicesSection = await _listCoreDevices(timeout: timeout);
    return <IOSCoreDevice>[
      for (final Object? deviceObject in devicesSection)
        if (deviceObject is Map<String, Object?>)
          IOSCoreDevice.fromBetaJson(deviceObject, logger: _logger),
    ];
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
  }

  /// Executes `devicectl` command to get list of apps installed on the device.
  /// If [bundleId] is provided, it will only return apps matching the bundle
  /// identifier exactly.
  Future<List<Object?>> _listInstalledApps({
    required String deviceId,
    String? bundleId,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return <Object?>[];
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('core_device_app_list.json');
    output.createSync();

    final List<String> command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'info',
      'apps',
      '--device',
      deviceId,
      if (bundleId != null)
        '--bundle-id',
        bundleId!,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);

      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['result'];
        if (decodeResult is Map<String, Object?>) {
          final Object? decodeApps = decodeResult['apps'];
          if (decodeApps is List<Object?>) {
            return decodeApps;
          }
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return <Object?>[];
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return <Object?>[];
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return <Object?>[];
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  @visibleForTesting
  Future<List<IOSCoreDeviceInstalledApp>> getInstalledApps({
    required String deviceId,
    String? bundleId,
  }) async {
<<<<<<< HEAD
    final List<IOSCoreDeviceInstalledApp> apps = <IOSCoreDeviceInstalledApp>[];

    final List<Object?> appsData = await _listInstalledApps(deviceId: deviceId, bundleId: bundleId);
    for (final Object? appObject in appsData) {
      if (appObject is Map<String, Object?>) {
        apps.add(IOSCoreDeviceInstalledApp.fromBetaJson(appObject));
      }
    }
    return apps;
=======
    final List<Object?> appsData = await _listInstalledApps(deviceId: deviceId, bundleId: bundleId);
    return <IOSCoreDeviceInstalledApp>[
      for (final Object? appObject in appsData)
        if (appObject is Map<String, Object?>)
          IOSCoreDeviceInstalledApp.fromBetaJson(appObject),
    ];
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
  }

  Future<bool> isAppInstalled({
    required String deviceId,
    required String bundleId,
  }) async {
    final List<IOSCoreDeviceInstalledApp> apps = await getInstalledApps(
      deviceId: deviceId,
      bundleId: bundleId,
    );
    if (apps.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<bool> installApp({
    required String deviceId,
    required String bundlePath,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return false;
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('install_results.json');
    output.createSync();

    final List<String> command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'install',
      'app',
      '--device',
      deviceId,
      bundlePath,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['info'];
        if (decodeResult is Map<String, Object?> && decodeResult['outcome'] == 'success') {
          return true;
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return false;
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return false;
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return false;
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  /// Uninstalls the app from the device. Will succeed even if the app is not
  /// currently installed on the device.
  Future<bool> uninstallApp({
    required String deviceId,
    required String bundleId,
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return false;
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('uninstall_results.json');
    output.createSync();

    final List<String> command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'uninstall',
      'app',
      '--device',
      deviceId,
      bundleId,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['info'];
        if (decodeResult is Map<String, Object?> && decodeResult['outcome'] == 'success') {
          return true;
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return false;
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return false;
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return false;
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  Future<bool> launchApp({
    required String deviceId,
    required String bundleId,
    List<String> launchArguments = const <String>[],
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printError('devicectl is not installed.');
      return false;
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('launch_results.json');
    output.createSync();

    final List<String> command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'device',
      'process',
      'launch',
      '--device',
      deviceId,
      bundleId,
      if (launchArguments.isNotEmpty) ...launchArguments,
      '--json-output',
      output.path,
    ];

    try {
      await _processUtils.run(command, throwOnError: true);
      final String stringOutput = output.readAsStringSync();

      try {
        final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['info'];
        if (decodeResult is Map<String, Object?> && decodeResult['outcome'] == 'success') {
          return true;
        }
        _logger.printError('devicectl returned unexpected JSON response: $stringOutput');
        return false;
      } on FormatException {
        // We failed to parse the devicectl output, or it returned junk.
        _logger.printError('devicectl returned non-JSON response: $stringOutput');
        return false;
      }
    } on ProcessException catch (err) {
      _logger.printError('Error executing devicectl: $err');
      return false;
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

class IOSCoreDevice {
  IOSCoreDevice._({
    required this.capabilities,
    required this.connectionProperties,
    required this.deviceProperties,
    required this.hardwareProperties,
<<<<<<< HEAD
    required this.coreDeviceIdentifer,
=======
    required this.coreDeviceIdentifier,
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
    required this.visibilityClass,
  });

  /// Parse JSON from `devicectl list devices --json-output` while it's in beta preview mode.
  ///
  /// Example:
  /// {
  ///   "capabilities" : [
  ///   ],
  ///   "connectionProperties" : {
  ///   },
  ///   "deviceProperties" : {
  ///   },
  ///   "hardwareProperties" : {
  ///   },
  ///   "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
  ///   "visibilityClass" : "default"
  /// }
  factory IOSCoreDevice.fromBetaJson(
    Map<String, Object?> data, {
    required Logger logger,
  }) {
<<<<<<< HEAD
    final List<_IOSCoreDeviceCapability> capabilitiesList = <_IOSCoreDeviceCapability>[];
    if (data['capabilities'] is List<Object?>) {
      final List<Object?> capabilitiesData = data['capabilities']! as List<Object?>;
      for (final Object? capabilityData in capabilitiesData) {
        if (capabilityData != null && capabilityData is Map<String, Object?>) {
          capabilitiesList.add(_IOSCoreDeviceCapability.fromBetaJson(capabilityData));
        }
      }
    }
=======
    final List<_IOSCoreDeviceCapability> capabilitiesList = <_IOSCoreDeviceCapability>[
      if (data['capabilities'] case final List<Object?> capabilitiesData)
        for (final Object? capabilityData in capabilitiesData)
          if (capabilityData != null && capabilityData is Map<String, Object?>)
            _IOSCoreDeviceCapability.fromBetaJson(capabilityData),
    ];
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730

    _IOSCoreDeviceConnectionProperties? connectionProperties;
    if (data['connectionProperties'] is Map<String, Object?>) {
      final Map<String, Object?> connectionPropertiesData = data['connectionProperties']! as Map<String, Object?>;
      connectionProperties = _IOSCoreDeviceConnectionProperties.fromBetaJson(
        connectionPropertiesData,
        logger: logger,
      );
    }

    IOSCoreDeviceProperties? deviceProperties;
    if (data['deviceProperties'] is Map<String, Object?>) {
      final Map<String, Object?> devicePropertiesData = data['deviceProperties']! as Map<String, Object?>;
      deviceProperties = IOSCoreDeviceProperties.fromBetaJson(devicePropertiesData);
    }

    _IOSCoreDeviceHardwareProperties? hardwareProperties;
    if (data['hardwareProperties'] is Map<String, Object?>) {
      final Map<String, Object?> hardwarePropertiesData = data['hardwareProperties']! as Map<String, Object?>;
      hardwareProperties = _IOSCoreDeviceHardwareProperties.fromBetaJson(
        hardwarePropertiesData,
        logger: logger,
      );
    }

    return IOSCoreDevice._(
      capabilities: capabilitiesList,
      connectionProperties: connectionProperties,
      deviceProperties: deviceProperties,
      hardwareProperties: hardwareProperties,
<<<<<<< HEAD
      coreDeviceIdentifer: data['identifier']?.toString(),
=======
      coreDeviceIdentifier: data['identifier']?.toString(),
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
      visibilityClass: data['visibilityClass']?.toString(),
    );
  }

  String? get udid => hardwareProperties?.udid;

  DeviceConnectionInterface? get connectionInterface {
<<<<<<< HEAD
    final String? transportType = connectionProperties?.transportType;
    if (transportType != null) {
      if (transportType.toLowerCase() == 'localnetwork') {
        return DeviceConnectionInterface.wireless;
      } else if (transportType.toLowerCase() == 'wired') {
        return DeviceConnectionInterface.attached;
      }
    }
    return null;
=======
    return switch (connectionProperties?.transportType?.toLowerCase()) {
      'localnetwork' => DeviceConnectionInterface.wireless,
      'wired'        => DeviceConnectionInterface.attached,
      _ => null,
    };
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
  }

  @visibleForTesting
  final List<_IOSCoreDeviceCapability> capabilities;

  @visibleForTesting
  final _IOSCoreDeviceConnectionProperties? connectionProperties;

  final IOSCoreDeviceProperties? deviceProperties;

  @visibleForTesting
  final _IOSCoreDeviceHardwareProperties? hardwareProperties;

<<<<<<< HEAD
  final String? coreDeviceIdentifer;
=======
  final String? coreDeviceIdentifier;
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
  final String? visibilityClass;
}


class _IOSCoreDeviceCapability {
  _IOSCoreDeviceCapability._({
    required this.featureIdentifier,
    required this.name,
  });

  /// Parse `capabilities` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "capabilities" : [
  ///   {
  ///     "featureIdentifier" : "com.apple.coredevice.feature.spawnexecutable",
  ///     "name" : "Spawn Executable"
  ///   },
  ///   {
  ///     "featureIdentifier" : "com.apple.coredevice.feature.launchapplication",
  ///     "name" : "Launch Application"
  ///   }
  /// ]
  factory _IOSCoreDeviceCapability.fromBetaJson(Map<String, Object?> data) {
    return _IOSCoreDeviceCapability._(
      featureIdentifier: data['featureIdentifier']?.toString(),
      name: data['name']?.toString(),
    );
  }

  final String? featureIdentifier;
  final String? name;
}

class _IOSCoreDeviceConnectionProperties {
  _IOSCoreDeviceConnectionProperties._({
    required this.authenticationType,
    required this.isMobileDeviceOnly,
    required this.lastConnectionDate,
    required this.localHostnames,
    required this.pairingState,
    required this.potentialHostnames,
    required this.transportType,
    required this.tunnelIPAddress,
    required this.tunnelState,
    required this.tunnelTransportProtocol,
  });

  /// Parse `connectionProperties` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "connectionProperties" : {
  ///   "authenticationType" : "manualPairing",
  ///   "isMobileDeviceOnly" : false,
  ///   "lastConnectionDate" : "2023-06-15T15:29:00.082Z",
  ///   "localHostnames" : [
  ///     "iPadName.coredevice.local",
  ///     "00001234-0001234A3C03401E.coredevice.local",
  ///     "12345BB5-AEDE-4A22-B653-6037262550DD.coredevice.local"
  ///   ],
  ///   "pairingState" : "paired",
  ///   "potentialHostnames" : [
  ///     "00001234-0001234A3C03401E.coredevice.local",
  ///     "12345BB5-AEDE-4A22-B653-6037262550DD.coredevice.local"
  ///   ],
  ///   "transportType" : "wired",
  ///   "tunnelIPAddress" : "fdf1:23c4:cd56::1",
  ///   "tunnelState" : "connected",
  ///   "tunnelTransportProtocol" : "tcp"
  /// }
  factory _IOSCoreDeviceConnectionProperties.fromBetaJson(
    Map<String, Object?> data, {
    required Logger logger,
  }) {
    List<String>? localHostnames;
    if (data['localHostnames'] is List<Object?>) {
      final List<Object?> values = data['localHostnames']! as List<Object?>;
      try {
        localHostnames = List<String>.from(values);
      } on TypeError {
        logger.printTrace('Error parsing localHostnames value: $values');
      }
    }

    List<String>? potentialHostnames;
    if (data['potentialHostnames'] is List<Object?>) {
      final List<Object?> values = data['potentialHostnames']! as List<Object?>;
      try {
        potentialHostnames = List<String>.from(values);
      } on TypeError {
        logger.printTrace('Error parsing potentialHostnames value: $values');
      }
    }
    return _IOSCoreDeviceConnectionProperties._(
      authenticationType: data['authenticationType']?.toString(),
      isMobileDeviceOnly: data['isMobileDeviceOnly'] is bool? ? data['isMobileDeviceOnly'] as bool? : null,
      lastConnectionDate: data['lastConnectionDate']?.toString(),
      localHostnames: localHostnames,
      pairingState: data['pairingState']?.toString(),
      potentialHostnames: potentialHostnames,
      transportType: data['transportType']?.toString(),
      tunnelIPAddress: data['tunnelIPAddress']?.toString(),
      tunnelState: data['tunnelState']?.toString(),
      tunnelTransportProtocol: data['tunnelTransportProtocol']?.toString(),
    );
  }

  final String? authenticationType;
  final bool? isMobileDeviceOnly;
  final String? lastConnectionDate;
  final List<String>? localHostnames;
  final String? pairingState;
  final List<String>? potentialHostnames;
  final String? transportType;
  final String? tunnelIPAddress;
  final String? tunnelState;
  final String? tunnelTransportProtocol;
}

@visibleForTesting
class IOSCoreDeviceProperties {
  IOSCoreDeviceProperties._({
    required this.bootedFromSnapshot,
    required this.bootedSnapshotName,
    required this.bootState,
    required this.ddiServicesAvailable,
    required this.developerModeStatus,
    required this.hasInternalOSBuild,
    required this.name,
    required this.osBuildUpdate,
    required this.osVersionNumber,
    required this.rootFileSystemIsWritable,
    required this.screenViewingURL,
  });

  /// Parse `deviceProperties` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "deviceProperties" : {
  ///   "bootedFromSnapshot" : true,
  ///   "bootedSnapshotName" : "com.apple.os.update-B5336980824124F599FD39FE91016493A74331B09F475250BB010B276FE2439E3DE3537349A3A957D3FF2A4B623B4ECC",
  ///   "bootState" : "booted",
  ///   "ddiServicesAvailable" : true,
  ///   "developerModeStatus" : "enabled",
  ///   "hasInternalOSBuild" : false,
  ///   "name" : "iPadName",
  ///   "osBuildUpdate" : "21A5248v",
  ///   "osVersionNumber" : "17.0",
  ///   "rootFileSystemIsWritable" : false,
  ///   "screenViewingURL" : "coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD"
  /// }
  factory IOSCoreDeviceProperties.fromBetaJson(Map<String, Object?> data) {
    return IOSCoreDeviceProperties._(
      bootedFromSnapshot: data['bootedFromSnapshot'] is bool? ? data['bootedFromSnapshot'] as bool? : null,
      bootedSnapshotName: data['bootedSnapshotName']?.toString(),
      bootState: data['bootState']?.toString(),
      ddiServicesAvailable: data['ddiServicesAvailable'] is bool? ? data['ddiServicesAvailable'] as bool? : null,
      developerModeStatus: data['developerModeStatus']?.toString(),
      hasInternalOSBuild: data['hasInternalOSBuild'] is bool? ? data['hasInternalOSBuild'] as bool? : null,
      name: data['name']?.toString(),
      osBuildUpdate: data['osBuildUpdate']?.toString(),
      osVersionNumber: data['osVersionNumber']?.toString(),
      rootFileSystemIsWritable: data['rootFileSystemIsWritable'] is bool? ? data['rootFileSystemIsWritable'] as bool? : null,
      screenViewingURL: data['screenViewingURL']?.toString(),
    );
  }

  final bool? bootedFromSnapshot;
  final String? bootedSnapshotName;
  final String? bootState;
  final bool? ddiServicesAvailable;
  final String? developerModeStatus;
  final bool? hasInternalOSBuild;
  final String? name;
  final String? osBuildUpdate;
  final String? osVersionNumber;
  final bool? rootFileSystemIsWritable;
  final String? screenViewingURL;
}

class _IOSCoreDeviceHardwareProperties {
  _IOSCoreDeviceHardwareProperties._({
    required this.cpuType,
    required this.deviceType,
    required this.ecid,
    required this.hardwareModel,
    required this.internalStorageCapacity,
    required this.marketingName,
    required this.platform,
    required this.productType,
    required this.serialNumber,
    required this.supportedCPUTypes,
    required this.supportedDeviceFamilies,
    required this.thinningProductType,
    required this.udid,
  });

  /// Parse `hardwareProperties` section of JSON from `devicectl list devices --json-output`
  /// while it's in beta preview mode.
  ///
  /// Example:
  /// "hardwareProperties" : {
  ///   "cpuType" : {
  ///     "name" : "arm64e",
  ///     "subType" : 2,
  ///     "type" : 16777228
  ///   },
  ///   "deviceType" : "iPad",
  ///   "ecid" : 12345678903408542,
  ///   "hardwareModel" : "J617AP",
  ///   "internalStorageCapacity" : 128000000000,
  ///   "marketingName" : "iPad Pro (11-inch) (4th generation)\"",
  ///   "platform" : "iOS",
  ///   "productType" : "iPad14,3",
  ///   "serialNumber" : "HC123DHCQV",
  ///   "supportedCPUTypes" : [
  ///     {
  ///       "name" : "arm64e",
  ///       "subType" : 2,
  ///       "type" : 16777228
  ///     },
  ///     {
  ///       "name" : "arm64",
  ///       "subType" : 0,
  ///       "type" : 16777228
  ///     }
  ///   ],
  ///   "supportedDeviceFamilies" : [
  ///     1,
  ///     2
  ///   ],
  ///   "thinningProductType" : "iPad14,3-A",
  ///   "udid" : "00001234-0001234A3C03401E"
  /// }
  factory _IOSCoreDeviceHardwareProperties.fromBetaJson(
    Map<String, Object?> data, {
    required Logger logger,
  }) {
    _IOSCoreDeviceCPUType? cpuType;
<<<<<<< HEAD
    if (data['cpuType'] is Map<String, Object?>) {
      cpuType = _IOSCoreDeviceCPUType.fromBetaJson(data['cpuType']! as Map<String, Object?>);
    }

    List<_IOSCoreDeviceCPUType>? supportedCPUTypes;
    if (data['supportedCPUTypes'] is List<Object?>) {
      final List<Object?> values = data['supportedCPUTypes']! as List<Object?>;
      final List<_IOSCoreDeviceCPUType> cpuTypes = <_IOSCoreDeviceCPUType>[];
      for (final Object? cpuTypeData in values) {
        if (cpuTypeData is Map<String, Object?>) {
          cpuTypes.add(_IOSCoreDeviceCPUType.fromBetaJson(cpuTypeData));
        }
      }
      supportedCPUTypes = cpuTypes;
=======
    if (data['cpuType'] case final Map<String, Object?> betaJson) {
      cpuType = _IOSCoreDeviceCPUType.fromBetaJson(betaJson);
    }

    List<_IOSCoreDeviceCPUType>? supportedCPUTypes;
    if (data['supportedCPUTypes'] case final List<Object?> values) {
      supportedCPUTypes = <_IOSCoreDeviceCPUType>[
        for (final Object? cpuTypeData in values)
          if (cpuTypeData is Map<String, Object?>)
            _IOSCoreDeviceCPUType.fromBetaJson(cpuTypeData),
      ];
>>>>>>> 2663184aa79047d0a33a14a3b607954f8fdd8730
    }

    List<int>? supportedDeviceFamilies;
    if (data['supportedDeviceFamilies'] is List<Object?>) {
      final List<Object?> values = data['supportedDeviceFamilies']! as List<Object?>;
      try {
        supportedDeviceFamilies = List<int>.from(values);
      } on TypeError {
        logger.printTrace('Error parsing supportedDeviceFamilies value: $values');
      }
    }

    return _IOSCoreDeviceHardwareProperties._(
      cpuType: cpuType,
      deviceType: data['deviceType']?.toString(),
      ecid: data['ecid'] is int? ? data['ecid'] as int? : null,
      hardwareModel: data['hardwareModel']?.toString(),
      internalStorageCapacity: data['internalStorageCapacity'] is int? ? data['internalStorageCapacity'] as int? : null,
      marketingName: data['marketingName']?.toString(),
      platform: data['platform']?.toString(),
      productType: data['productType']?.toString(),
      serialNumber: data['serialNumber']?.toString(),
      supportedCPUTypes: supportedCPUTypes,
      supportedDeviceFamilies: supportedDeviceFamilies,
      thinningProductType: data['thinningProductType']?.toString(),
      udid: data['udid']?.toString(),
    );
  }

  final _IOSCoreDeviceCPUType? cpuType;
  final String? deviceType;
  final int? ecid;
  final String? hardwareModel;
  final int? internalStorageCapacity;
  final String? marketingName;
  final String? platform;
  final String? productType;
  final String? serialNumber;
  final List<_IOSCoreDeviceCPUType>? supportedCPUTypes;
  final List<int>? supportedDeviceFamilies;
  final String? thinningProductType;
  final String? udid;
}

class _IOSCoreDeviceCPUType {
  _IOSCoreDeviceCPUType._({
    this.name,
    this.subType,
    this.cpuType,
  });

  /// Parse `hardwareProperties.cpuType` and `hardwareProperties.supportedCPUTypes`
  /// sections of JSON from `devicectl list devices --json-output` while it's in beta preview mode.
  ///
  /// Example:
  /// "cpuType" : {
  ///   "name" : "arm64e",
  ///   "subType" : 2,
  ///   "type" : 16777228
  /// }
  factory _IOSCoreDeviceCPUType.fromBetaJson(Map<String, Object?> data) {
    return _IOSCoreDeviceCPUType._(
      name: data['name']?.toString(),
      subType: data['subType'] is int? ? data['subType'] as int? : null,
      cpuType: data['type'] is int? ? data['type'] as int? : null,
    );
  }

  final String? name;
  final int? subType;
  final int? cpuType;
}

@visibleForTesting
class IOSCoreDeviceInstalledApp {
  IOSCoreDeviceInstalledApp._({
    required this.appClip,
    required this.builtByDeveloper,
    required this.bundleIdentifier,
    required this.bundleVersion,
    required this.defaultApp,
    required this.hidden,
    required this.internalApp,
    required this.name,
    required this.removable,
    required this.url,
    required this.version,
  });

  /// Parse JSON from `devicectl device info apps --json-output` while it's in
  /// beta preview mode.
  ///
  /// Example:
  /// {
  ///   "appClip" : false,
  ///   "builtByDeveloper" : true,
  ///   "bundleIdentifier" : "com.example.flutterApp",
  ///   "bundleVersion" : "1",
  ///   "defaultApp" : false,
  ///   "hidden" : false,
  ///   "internalApp" : false,
  ///   "name" : "Flutter App",
  ///   "removable" : true,
  ///   "url" : "file:///private/var/containers/Bundle/Application/12345E6A-7F89-0C12-345E-F6A7E890CFF1/Runner.app/",
  ///   "version" : "1.0.0"
  /// }
  factory IOSCoreDeviceInstalledApp.fromBetaJson(Map<String, Object?> data) {
    return IOSCoreDeviceInstalledApp._(
      appClip: data['appClip'] is bool? ? data['appClip'] as bool? : null,
      builtByDeveloper: data['builtByDeveloper'] is bool? ? data['builtByDeveloper'] as bool? : null,
      bundleIdentifier: data['bundleIdentifier']?.toString(),
      bundleVersion: data['bundleVersion']?.toString(),
      defaultApp: data['defaultApp'] is bool? ? data['defaultApp'] as bool? : null,
      hidden: data['hidden'] is bool? ? data['hidden'] as bool? : null,
      internalApp: data['internalApp'] is bool? ? data['internalApp'] as bool? : null,
      name: data['name']?.toString(),
      removable: data['removable'] is bool? ? data['removable'] as bool? : null,
      url: data['url']?.toString(),
      version: data['version']?.toString(),
    );
  }

  final bool? appClip;
  final bool? builtByDeveloper;
  final String? bundleIdentifier;
  final String? bundleVersion;
  final bool? defaultApp;
  final bool? hidden;
  final bool? internalApp;
  final String? name;
  final bool? removable;
  final String? url;
  final String? version;
}
