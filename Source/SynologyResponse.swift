//
//  SynologyResponse.swift
//  SynologyKit
//
//  Created by xu.shuifeng on 20/09/2017.
//

import Foundation
import Alamofire

struct SynologyResponse<T>: Codable where T: Codable {
    public var success: Bool
    public var data: T?
    public var error: Int?
}



public enum SynologyError: Error, CustomStringConvertible {
    case invalidResponse(DefaultDataResponse)
    case decodeDataError(DefaultDataResponse, String?)
    case serverError(Int, String, DefaultDataResponse)
    
    public var description: String {
        switch self {
        case .invalidResponse(let res):
            debugPrint(res)
            return "Invalid Server Response"
        case .decodeDataError(let res, let html):
            debugPrint(res)
            if let html = html {
                debugPrint(html)
            }
            return "Decode Error"
        case .serverError(let code, let message, let res):
            debugPrint("Error Code:\(code), response: \(res)")
            return message
        }
    }
}

public struct QuickIDResponse: Codable {
    public let command: String
    public let version: Int
    public let errno: Int
    public let service: QuickIDService?
}

public struct QuickIDService: Codable {
    
    enum CodingKeys: String, CodingKey {
        case relayIP = "relay_ip"
        case relayPort = "relay_port"
        case env
    }
    
    public let relayIP: String?
    public let relayPort: Int?
    public let env: QuickIDEnv?
}

public struct QuickIDEnv: Codable {
    
    enum CodingKeys: String, CodingKey {
        case relayRegion = "relay_region"
        case controlHost = "control_host"
    }
    
    let relayRegion: String
    let controlHost: String
}

public extension SynologyClient {
    
    struct AuthResponse: Codable {
        
        /// Authorized session ID. When the user log in with format=sid,
        /// cookie will not be set and each API request should provide a request parameter _sid=< sid> along with other parameters.
        public let sid: String
    }
    
    struct EmptyResponse: Codable {
        
    }
    
    struct FileStationInfo: Codable {
        
        enum CodingKeys: String, CodingKey {
            case hostname
            case isManager = "is_manager"
            case supportSharing = "support_sharing"
            case supportVirtualProtocol = "support_virtual_protocol"
        }
        
        /// DSM host name
        public var hostname: String

        /// If the logged-in user can sharing file(s)/folder(s) or not.
        public var supportSharing: Bool
        
        /// If the logged-in user is an administrator.
        public var isManager: Bool
        
        /// Types of virtual file system which the logged user is able to mount on.
        /// DSM 4.3 supports CIFS and ISO of virtual file system.
        /// Different types are separated with a comma, for example: cifs,iso.
        public var supportVirtualProtocol: Bool
    }
    
    /// Common Non-Blocking Task Response
    struct Task: Codable {
        public let taskid: String?
    }
    
    struct SharedFolders: Codable {
        
        /// Total number of shared folders.
        public let total: Int
        
        /// Requested offset.
        public let offset: Int
        
        /// Array of <shared folder> objects.
        public let shares: [SharedFolder]?
    }
    
    struct SharedFolder: Codable {
        public let isdir: Bool
        
        /// Path of a shared folder.
        public let path: String
        
        /// Name of a shared folder.
        public let name: String?
        
        /// Shared-folder additional object.
        public let additional: Additional?
        
        public func toFile() -> File {
            return File(path: path, name: name, isdir: isdir, children: nil, additional: additional)
        }
    }
    
    struct VirtualFolderList: Codable {
        /// Total number of mount point folders.
        public let total: Int
        
        /// Requested offset.
        public let offset: Int
        
        /// Array of <virtual folder> object.
        public let folders: [VirtualFolder]?
    }
    
    struct VirtualFolder: Codable {
        
        /// Path of a mount point folder
        public let path: String
        
        /// Name of a mount point folder
        public let name: String?
        
        /// Virtual folder additional object.
        public let additional: Additional?
    }
    
    struct Files: Codable {
        
        /// Total number of files
        public let total: Int
        
        /// Requested offset
        public let offset: Int
        
        /// Array of <file> objects
        public let files: [File]?
    }

    struct File: Codable {
        
        /// Folder/file path started with a shared folder
        public let path: String
        
        /// File name
        public let name: String?
        
        /// If this file is folder or not
        public let isdir: Bool
        
        /// File list within a folder which is described by a <file> object.
        /// The value is returned, only if goto_path parameter is given
        public let children: Files?
        
        /// File additional object
        public let additional: Additional?
    }
    
    struct Additional: Codable {
        
        enum CodingKeys: String, CodingKey {
            case realPath = "real_path"
            case size
            case owner
            case time
            case mountPointType = "mount_point_type"
            case volumeStatus = "volume_status"
            case type
        }
        
        /// Real path of a shared folder in a volume space.
        public let realPath: String?
        
        /// File size in bytes
        public let size: Int?
        
        /// File owner information including user name, group name, UID and GID.
        public let owner: Owner?
        
        /// Time information of file including last access time, last modified time, last change time, and creation time.
        public let time: FileTime?
        
        /// Type of a virtual file system of a mount point
        public let mountPointType: String?
        
        /// Volume status including free space, total space and read-only status.
        public let volumeStatus: VolumeStatus?
        public let type: String?
    }

    struct VolumeStatus: Codable {
        
        /// Byte size of free space of a volume where a shared folder is located.
        public let freespace: Int
        
        /// Byte size of total space of a volume where a shared folder is located.
        let totalspace: Int
        
        /// “true”: A volume where a shared folder is located isread-only;
        /// “false”: It’s writable.
        let readonly: Bool
    }

    struct Owner: Codable {
        
        /// User name of file owner.
        public let user: String
        
        /// Group name of file group.
        public let group: String
        
        /// File UID.
        public let uid: Int
        
        /// File GID
        public let gid: Int
    }

    struct FileTime: Codable {
        
        enum CodingKeys: String, CodingKey {
            case accessTime = "atime"
            case modifiedTime = "mtime"
            case changedTime = "ctime"
            case createTime = "crtime"
        }
        
        /// Linux timestamp of last access in second.
        let accessTime: TimeInterval?
        public var accessDate: Date? {
            return Date(timeIntervalSince1970: accessTime ?? 0)
        }
        
        let modifiedTime: TimeInterval?
        public var modifiedDate: Date? {
            return Date(timeIntervalSince1970: modifiedTime ?? 0)
        }
        
        let changedTime: TimeInterval?
        public var changedDate: Date? {
            return Date()
        }
        
        let createTime: TimeInterval?
        public var createDate: Date? {
            return Date()
        }
    }
    
    struct DirectorySizeStatus: Codable {
        enum CodingKeys: String, CodingKey {
            case finished
            case numberOfDirectory = "num_dir"
            case numberOfFiles = "num_file"
            case totalSize = "total_size"
        }
        
        /// If the task is finished or not.
        public let finished: Bool
        
        /// Number of directories in the queried path(s).
        public let numberOfDirectory: Int
        
        /// Number of files in the queried path(s).
        public let numberOfFiles: Int
        
        /// Accumulated byte size of the queried path(s).
        public let totalSize: Int64
    }
    
    struct MD5Status: Codable {
        
        /// Check if the task is finished or not.
        public let finished: Bool
        
        /// MD5 of the requested file.
        public let md5: String?
    }
    
    struct CopyMoveStatus: Codable {
        enum CodingKeys: String, CodingKey {
            case processedSize = "processed_size"
            case total
            case path
            case finished
            case progress
            case destinationFolderPath = "dest_folder_path"
        }
        
        /// If accurate_progress parameter is “true,” byte sizes of all copied/moved files will be accumulated.
        /// If “false,” only byte sizes of the file you give in path parameter is accumulated.
        public let processedSize: Int64
        
        /// If accurate_progress parameter is “true,” the value indicates total byte sizes of files including subfolders will be copied/moved.
        /// If “false,” it indicates total byte sizes of files you give in path parameter excluding files within subfolders.
        /// Otherwise, when the total number is calculating, the value is -1.
        public let total: Int64
        
        /// A copying/moving path which you give in path parameter.
        public let path: String
        
        /// If the copy/move task is finished or not.
        public let finished: Bool
        
        /// A progress value is between 0~1. It is equal to processed_size parameter divided by total parameter.
        public let progress: Float
        
        /// A desitination folder path where files/folders are copied/moved.
        public let destinationFolderPath: String?
    }
    
    struct DeletionStatus: Codable {
        enum CodingKeys: String, CodingKey {
            case processdNumber = "processed_num"
            case total
            case path
            case processingPath = "processing_path"
            case finished
            case progress
        }
        
        /// If accurate_progress parameter is “true,” the number of all deleted files will be accumulated.
        /// If “false,” only the number of file you give in path parameter is accumulated.
        public let processdNumber: Int64
        
        /// If accurate_progress parameter is “true,” the value indicates how many files including subfolders will be deleted.
        /// If “false,” it indicates how many files you give in path parameter. When the total number is calculating, the value is -1.
        public let total: Int64
        
        /// A deletion path which you give in path parameter.
        public let path: String
        
        /// A deletion path which could be located at a subfolder.
        public let processingPath: String?
        
        /// Whether or not the deletion task is finished.
        public let finished: Bool
        
        /// Progress value whose range between 0~1 is equal to processed_num parameter divided by total parameter.
        public let progress: Float
    }
    
    struct ExtractStatus: Codable {
        
        enum CodingKeys: String, CodingKey {
            case finished
            case progress
            case destinationFolderPath = "dest_folder_path"
        }
        
        /// If the task is finished or not.
        public let finished: Bool
        
        /// The extract progress expressed in range 0 to 1.
        public let progress: Float
        
        /// The requested destination folder for the task.
        public let destinationFolderPath: String
    }
    
    struct CompressionStatus: Codable {
        enum CodingKeys: String, CodingKey {
            case finished
            case destinationFilePath = "dest_file_path"
        }
        
        /// Whether or not the compress task is finished.
        public let finished: Bool
        
        /// The requested destination path of an archive.
        public let destinationFilePath: String?
    }

}
