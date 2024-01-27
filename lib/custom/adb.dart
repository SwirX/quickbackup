// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

enum ptConnectionState { connected, disconnected, unknown }

enum ptConnectionType { wired, wireless }

enum ptConnectionMode { adb, fastboot }

enum ptConnectionError { noDeviceConn, noAuth, none }

class ptFile {
  String path;
  String name;
  String extension;
  String size;
  DateTime? modified;
  Uint16List? hash;
  Uint8List data = Uint8List(0);
  String stringData = "";

  ptFile(
    this.path,
    this.name,
    this.extension,
    this.size,
    this.modified,
  );
}

class ptDirectory {
  String path;
  String name;
  List<ptDirectory> subDirs = [];
  List<ptFile> files = [];

  ptDirectory(this.path, this.name);

  bool isEmpty() {
    return subDirs.isEmpty && files.isEmpty;
  }

  bool isNotEmpty() {
    return !isEmpty();
  }

  void addSubDir(ptDirectory subDir) {
    subDirs.add(subDir);
  }

  void addFile(ptFile file) {
    files.add(file);
  }

  void addSubDirFromPath(String path) {
    var subDir = ptDirectory(path, path.split("/").last);
    subDirs.add(subDir);
  }

  ptDirectory getSubDir(String name) {
    for (var subDir in subDirs) {
      if (subDir.name == name) {
        return subDir;
      }
    }
    return ptDirectory("$path/$name", name);
  }

  ptFile getFile(String name) {
    for (var file in files) {
      if (file.name == name) {
        return file;
      }
    }
    return ptFile("$path/$name", name, "", "", DateTime.now());
  }

  List<ptFile> getFilesByExtention(String extention) {
    var files = [] as List<ptFile>;
    for (var file in this.files) {
      if (file.extension == extention) {
        files.add(file);
      }
    }
    return files;
  }
}

class ptConnection {
  ptConnectionState state;
  ptConnectionType type;
  ptConnectionMode mode;
  String deviceID;
  ptConnectionError error;

  ptConnection(this.state, this.type, this.mode, this.deviceID, this.error);
}

class pt {
  Future<ptConnection> checkConnection() async {
    var res = await Process.run("adb", ["devices"]);
    final formatedRes = res.stdout
        .toString()
        .replaceAll("\t", " ")
        .replaceAll("\r", "")
        .replaceAll("\n", " ");
    if (res.exitCode == 0) {
      var deviceID = formatedRes.split(" ")[4];
      if (deviceID.isNotEmpty) {
        if (formatedRes.contains("unauthorized")) {
          return ptConnection(
            ptConnectionState.connected,
            ptConnectionType.wired,
            ptConnectionMode.adb,
            deviceID,
            ptConnectionError.noAuth,
          );
        } else {
          return ptConnection(
            ptConnectionState.connected,
            ptConnectionType.wired,
            ptConnectionMode.adb,
            deviceID,
            ptConnectionError.none,
          );
        }
      } else {
        return ptConnection(
          ptConnectionState.disconnected,
          ptConnectionType.wired,
          ptConnectionMode.adb,
          "not connected",
          ptConnectionError.noDeviceConn,
        );
      }
    } else {
      return ptConnection(
        ptConnectionState.disconnected,
        ptConnectionType.wired,
        ptConnectionMode.adb,
        "not connected",
        ptConnectionError.noDeviceConn,
      );
    }
  }

  void rebootToBootloader() async {
    await Process.run("adb", ["reboot", "bootloader"]);
  }

  void rebootToRecovery() async {
    await Process.run("adb", ["reboot", "recovery"]);
  }

  void installApk(String path) async {
    await Process.run("adb", ["install", "-r", path]);
  }

  void uninstallApk(String packageName) async {
    await Process.run("adb", ["uninstall", packageName]);
  }

  Future<bool> isAppInstalled(String packageName) async {
    var res = await Process.run("adb", ["shell", "pm", "list", "packages"]);
    final formatedRes = res.stdout
        .toString()
        .replaceAll("\t", " ")
        .replaceAll("\r", "")
        .replaceAll("\n", " ");
    if (res.exitCode == 0) {
      return formatedRes.contains(packageName);
    } else {
      return false;
    }
  }

  Future<String> getPackageName(String appName) async {
    var res = await Process.run(
        "adb", ["shell", "pm", "list", "packages", "|", "grep", appName]);
    return res.stdout
        .toString()
        .replaceAll("package:", "")
        .replaceAll("\n", "")
        .replaceAll("\r", "");
  }

  Future<String> getAppVersion(String packageName) async {
    var res =
        await Process.run("adb", ["shell", "dumpsys", "package", packageName]);
    final formatedRes = res.stdout
        .toString()
        .replaceAll("\t", " ")
        .replaceAll("\r", "")
        .replaceAll("\n", " ");
    if (res.exitCode == 0) {
      return formatedRes.split("versionName=")[1].split(" ")[0];
    } else {
      return "unknown";
    }
  }

  Future<String> getAppPath(String packageName) async {
    var res = await Process.run("adb", ["shell", "pm", "path", packageName]);
    final formatedRes = res.stdout
        .toString()
        .replaceAll("\t", " ")
        .replaceAll("\r", "")
        .replaceAll("\n", " ");
    if (res.exitCode == 0) {
      return formatedRes.split("package:")[1].split(" ")[0];
    } else {
      return "unknown";
    }
  }

  Future<ptDirectory> getDirectory(String path) async {
    var dir = ptDirectory(path, path.split("/").last);
    var res = await Process.run("adb", ["shell", "ls", "-l", path]);
    final formatedRes = res.stdout
        .toString()
        .replaceAll("\t", " ")
        .replaceAll("\r", "")
        .replaceAll("\n", " ");
    if (res.exitCode == 0) {
      var files = formatedRes.split(" ");
      for (var file in files) {
        if (file.contains("d")) {
          dir.addSubDirFromPath(file);
        } else {
          var name = file.split("/").last;
          var extension = name.split(".").last;
          var size = file.split(" ")[4];
          dir.addFile(ptFile(path, name, extension, size, null));
        }
      }
    }
    return dir;
  }

  // In Progress

  // Future<ptFile> getFile(String path) async {
  //   var file = ptFile(path, path.split("/").last, "", "", DateTime.now());
  //   var res = await Process.run("adb", ["shell", "ls", "-l", path]);
  //   final formatedRes = res.stdout
  //       .toString()
  //       .replaceAll("\t", " ")
  //       .replaceAll("\r", "")
  //       .replaceAll("\n", " ");
  //   if (res.exitCode == 0) {
  //     var files = formatedRes.split(" ");
  //     for (var file in files) {
  //       if (file.contains("d")) {
  //         file.addSubDirFromPath(file);
  //       } else {
  //         var name = file.split("/").last;
  //         var extension = name.split(".").last;
  //         var size = file.split(" ")[4];
  //         file.addFile(ptFile(path, name, extension, size, null));
  //       }
  //     }
  //   }
  //   return file;
  // }
}
