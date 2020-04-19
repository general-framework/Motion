import Foundation
import CoreMotion
import os.log

extension OSLog {

    static let accelerometer = OSLog(subsystem: "Motion", category: "accelerometer")
    static let gyro = OSLog(subsystem: "Motion", category: "gyro")
    static let magnetometer = OSLog(subsystem: "Motion", category: "magnetometer")
    static let deviceMotion = OSLog(subsystem: "Motion", category: "device-motion")
}

//_______________________________________________________________________________________________________________
// this helps retrieve values from the sensors.
@objc protocol MotionKitDelegate {
    @objc optional func retrieveAccelerometerValues (x: Double, y:Double, z:Double, absoluteValue: Double)
    @objc optional func retrieveGyroscopeValues     (x: Double, y:Double, z:Double, absoluteValue: Double)
    @objc optional func retrieveDeviceMotionObject  (deviceMotion: CMDeviceMotion)
    @objc optional func retrieveMagnetometerValues  (x: Double, y:Double, z:Double, absoluteValue: Double)
    
    @objc optional func getAccelerationValFromDeviceMotion        (x: Double, y:Double, z:Double)
    @objc optional func getGravityAccelerationValFromDeviceMotion (x: Double, y:Double, z:Double)
    @objc optional func getRotationRateFromDeviceMotion           (x: Double, y:Double, z:Double)
    @objc optional func getMagneticFieldFromDeviceMotion          (x: Double, y:Double, z:Double)
    @objc optional func getAttitudeFromDeviceMotion               (attitude: CMAttitude)
}


@objc(MotionKit) public class MotionKit :NSObject{
    
    let manager = CMMotionManager()
    var delegate: MotionKitDelegate?
    
    /*
    *  init:void:
    *
    *  Discussion:
    *   Initialises the MotionKit class and throw a Log with a timestamp.
    */
    public override init(){
        NSLog("MotionKit has been initialised successfully")
    }
    
    /*
    *  getAccelerometerValues:interval:values:
    *
    *  Discussion:
    *   Starts accelerometer updates, providing data to the given handler through the given queue.
    *   Note that when the updates are stopped, all operations in the
    *   given NSOperationQueue will be cancelled. You can access the retrieved values either by a
    *   Trailing Closure or through a Delgate.
    */
    public func getAccelerometerValues (interval: TimeInterval = 0.1, values: ((_ x: Double, _ y: Double, _ z: Double) -> ())? ){
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = interval
            manager.startAccelerometerUpdates(to: OperationQueue(), withHandler: {
                (data, error) in
                
                if let isError = error {
                    os_log("Error: %@", log: OSLog.accelerometer, type: .error, isError.localizedDescription)
                }
                valX = data!.acceleration.x
                valY = data!.acceleration.y
                valZ = data!.acceleration.z
                
                if values != nil{
                    values!(valX,valY,valZ)
                }
                let absoluteVal = sqrt(pow(valX,2) + pow(valY,2) + pow(valZ,2))
                self.delegate?.retrieveAccelerometerValues!(x: valX, y: valY, z: valZ, absoluteValue: absoluteVal)
            })
        } else {
            NSLog("The Accelerometer is not available")
        }
    }
    
    /*
    *  getGyroValues:interval:values:
    *
    *  Discussion:
    *   Starts gyro updates, providing data to the given handler through the given queue.
    *   Note that when the updates are stopped, all operations in the
    *   given NSOperationQueue will be cancelled. You can access the retrieved values either by a
    *   Trailing Closure or through a Delegate.
    */
    public func getGyroValues (interval: TimeInterval = 0.1, values: ((_ x: Double, _ y: Double, _ z:Double) -> ())? ) {
        
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        if manager.isGyroAvailable {
            manager.gyroUpdateInterval = interval
            manager.startGyroUpdates(to: OperationQueue(), withHandler: {
                (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.gyro, type: .error, isError.localizedDescription)
                }
                valX = data!.rotationRate.x
                valY = data!.rotationRate.y
                valZ = data!.rotationRate.z
                
                if values != nil{
                    values!(valX, valY, valZ)
                }
                let absoluteVal = sqrt(pow(valX,2) + pow(valY,2) + pow(valZ,2))
                self.delegate?.retrieveGyroscopeValues!(x: valX, y: valY, z: valZ, absoluteValue: absoluteVal)
            })
            
        } else {
            NSLog("The Gyroscope is not available")
        }
    }
    
    /*
    *  getMagnetometerValues:interval:values:
    *
    *  Discussion:
    *   Starts magnetometer updates, providing data to the given handler through the given queue.
    *   You can access the retrieved values either by a Trailing Closure or through a Delegate.
    */
    @available(iOS, introduced: 5.0)
    public func getMagnetometerValues (interval: TimeInterval = 0.1, values: ((_ x: Double, _ y:Double, _ z:Double) -> ())? ){
        
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        if manager.isMagnetometerAvailable {
            manager.magnetometerUpdateInterval = interval
            manager.startMagnetometerUpdates(to: OperationQueue()){
                (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.magnetometer, type: .error, isError.localizedDescription)
                }
                valX = data!.magneticField.x
                valY = data!.magneticField.y
                valZ = data!.magneticField.z
                
                if values != nil{
                    values!(valX, valY, valZ)
                }
                let absoluteVal = sqrt(pow(valX,2) + pow(valY,2) + pow(valZ,2))
                self.delegate?.retrieveMagnetometerValues!(x: valX, y: valY, z: valZ, absoluteValue: absoluteVal)
            }
            
        } else {
            NSLog("Magnetometer is not available")
        }
    }
    
    /*  MARK :- DEVICE MOTION APPROACH STARTS HERE  */
    
    /*
    *  getDeviceMotionValues:interval:values:
    *
    *  Discussion:
    *   Starts device motion updates, providing data to the given handler through the given queue.
    *   Uses the default reference frame for the device. Examine CMMotionManager's
    *   attitudeReferenceFrame to determine this. You can access the retrieved values either by a
    *   Trailing Closure or through a Delegate.
    */
    public func getDeviceMotionObject (interval: TimeInterval = 0.1, values: ((_ deviceMotion: CMDeviceMotion) -> ())? ) {
        
        if manager.isDeviceMotionAvailable{
            manager.deviceMotionUpdateInterval = interval
            manager.startDeviceMotionUpdates(to: OperationQueue()){
                (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.deviceMotion, type: .error, isError.localizedDescription)
                }
                if values != nil{
                    values!(data!)
                }
                self.delegate?.retrieveDeviceMotionObject!(deviceMotion: data!)
            }
            
        } else {
            NSLog("Device Motion is not available")
        }
    }
    
    
    /*
    *   getAccelerationFromDeviceMotion:interval:values:
    *   You can retrieve the processed user accelaration data from the device motion from this method.
    */
    public func getAccelerationFromDeviceMotion (interval: TimeInterval = 0.1, values: ((_ x:Double, _ y:Double, _ z:Double) -> ())? ) {
        
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        if manager.isDeviceMotionAvailable{
            manager.deviceMotionUpdateInterval = interval
            manager.startDeviceMotionUpdates(to: OperationQueue()){
                (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.deviceMotion, type: .error, isError.localizedDescription)
                }
                valX = data!.userAcceleration.x
                valY = data!.userAcceleration.y
                valZ = data!.userAcceleration.z
                
                if values != nil{
                    values!(valX, valY, valZ)
                }
                
                self.delegate?.getAccelerationValFromDeviceMotion!(x: valX, y: valY, z: valZ)
            }
            
        } else {
            NSLog("Device Motion is unavailable")
        }
    }
    
    /*
    *   getGravityAccelerationFromDeviceMotion:interval:values:
    *   You can retrieve the processed gravitational accelaration data from the device motion from this
    *   method.
    */
    public func getGravityAccelerationFromDeviceMotion (interval: TimeInterval = 0.1, values: ((_ x:Double, _ y:Double, _ z:Double) -> ())? ) {
        
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        if manager.isDeviceMotionAvailable{
            manager.deviceMotionUpdateInterval = interval
            manager.startDeviceMotionUpdates(to: OperationQueue()){
                (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.deviceMotion, type: .error, isError.localizedDescription)
                }
                valX = data!.gravity.x
                valY = data!.gravity.y
                valZ = data!.gravity.z
                
                if values != nil{
                    values!(valX, valY, valZ)
                }

                self.delegate?.getGravityAccelerationValFromDeviceMotion!(x: valX, y: valY, z: valZ)
            }
            
        } else {
            NSLog("Device Motion is not available")
        }
    }
    
    
    /*
    *   getAttitudeFromDeviceMotion:interval:values:
    *   You can retrieve the processed attitude data from the device motion from this
    *   method.
    */
    public func getAttitudeFromDeviceMotion (interval: TimeInterval = 0.1, values: ((_ attitude: CMAttitude) -> ())? ) {
        
        if manager.isDeviceMotionAvailable{
            manager.deviceMotionUpdateInterval = interval
            manager.startDeviceMotionUpdates(to: OperationQueue()){
                 (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.deviceMotion, type: .error, isError.localizedDescription)
                }
                if values != nil{
                    values!(data!.attitude)
                }
                
                self.delegate?.getAttitudeFromDeviceMotion!(attitude: data!.attitude)
            }
            
        } else {
            NSLog("Device Motion is not available")
        }
    }
    
    /*
    *   getRotationRateFromDeviceMotion:interval:values:
    *   You can retrieve the processed rotation data from the device motion from this
    *   method.
    */
    public func getRotationRateFromDeviceMotion (interval: TimeInterval = 0.1, values: ((_ x:Double, _ y:Double, _ z:Double) -> ())? ) {
        
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        if manager.isDeviceMotionAvailable{
            manager.deviceMotionUpdateInterval = interval
            manager.startDeviceMotionUpdates(to: OperationQueue()){
                 (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.deviceMotion, type: .error, isError.localizedDescription)
                }
                valX = data!.rotationRate.x
                valY = data!.rotationRate.y
                valZ = data!.rotationRate.z
                
                if values != nil{
                    values!(valX, valY, valZ)
                }
            
                self.delegate?.getRotationRateFromDeviceMotion!(x: valX, y: valY, z: valZ)
            }
            
        } else {
            NSLog("Device Motion is not available")
        }
    }
    
    
    /*
    *   getMagneticFieldFromDeviceMotion:interval:values:
    *   You can retrieve the processed magnetic field data from the device motion from this
    *   method.
    */
    public func getMagneticFieldFromDeviceMotion (interval: TimeInterval = 0.1, values: ((_ x:Double, _ y:Double, _ z:Double, _ accuracy: Int32) -> ())? ) {
        
        var valX: Double!
        var valY: Double!
        var valZ: Double!
        var valAccuracy: Int32!
        if manager.isDeviceMotionAvailable{
            manager.deviceMotionUpdateInterval = interval
            manager.startDeviceMotionUpdates(to: OperationQueue()){
                 (data, error) in
                
                if let isError = error{
                    os_log("Error: %@", log: OSLog.deviceMotion, type: .error, isError.localizedDescription)
                }
                valX = data!.magneticField.field.x
                valY = data!.magneticField.field.y
                valZ = data!.magneticField.field.z
                valAccuracy = data!.magneticField.accuracy.rawValue
                
                if values != nil{
                    values!(valX, valY, valZ, valAccuracy)
                }
                
                self.delegate?.getMagneticFieldFromDeviceMotion!(x: valX, y: valY, z: valZ)
            }
            
        } else {
            NSLog("Device Motion is not available")
        }
    }
    
    /*  MARK :- DEVICE MOTION APPROACH ENDS HERE    */
    
    
    /*
    *   From the methods hereafter, the sensor values could be retrieved at
    *   a particular instant, whenever needed, through a trailing closure.
    */
    
    /*  MARK :- INSTANTANIOUS METHODS START HERE  */
    
    public func getAccelerationAtCurrentInstant (values: @escaping (_ x:Double, _ y:Double, _ z:Double) -> ()){
        self.getAccelerationFromDeviceMotion(interval: 0.5) { (x, y, z) -> () in
            values(x,y,z)
            self.stopDeviceMotionUpdates()
        }
    }
    
    public func getGravitationalAccelerationAtCurrentInstant (values: @escaping (_ x:Double, _ y:Double, _ z:Double) -> ()){
        self.getGravityAccelerationFromDeviceMotion(interval: 0.5) { (x, y, z) -> () in
            values(x,y,z)
            self.stopDeviceMotionUpdates()
        }
    }
    
    public func getAttitudeAtCurrentInstant (values: @escaping (_ attitude: CMAttitude) -> ()){
        self.getAttitudeFromDeviceMotion(interval: 0.5) { (attitude) -> () in
            values(attitude)
            self.stopDeviceMotionUpdates()
        }
    
    }
    
    public func getMageticFieldAtCurrentInstant (values: @escaping (_ x:Double,_ y:Double,_ z:Double) -> ()){
        self.getMagneticFieldFromDeviceMotion(interval: 0.5) { (x, y, z, accuracy) -> () in
            values(x,y,z)
            self.stopDeviceMotionUpdates()
        }
    }
    
    public func getGyroValuesAtCurrentInstant (values: @escaping (_ x:Double, _ y:Double, _ z:Double) -> ()){
        self.getRotationRateFromDeviceMotion(interval: 0.5) { (x, y, z) -> () in
            values(x,y,z)
            self.stopDeviceMotionUpdates()
        }
    }
    
    /*  MARK :- INSTANTANIOUS METHODS END HERE  */
    
    
    
    /*
    *  stopAccelerometerUpdates
    *
    *  Discussion:
    *   Stop accelerometer updates.
    */
    public func stopAccelerometerUpdates(){
        self.manager.stopAccelerometerUpdates()
        NSLog("Accelaration Updates Status - Stopped")
    }
    
    /*
    *  stopGyroUpdates
    *
    *  Discussion:
    *   Stops gyro updates.
    */
    public func stopGyroUpdates(){
        self.manager.stopGyroUpdates()
        NSLog("Gyroscope Updates Status - Stopped")
    }
    
    /*
    *  stopDeviceMotionUpdates
    *
    *  Discussion:
    *   Stops device motion updates.
    */
    public func stopDeviceMotionUpdates() {
        self.manager.stopDeviceMotionUpdates()
        NSLog("Device Motion Updates Status - Stopped")
    }
    
    /*
    *  stopMagnetometerUpdates
    *
    *  Discussion:
    *   Stops magnetometer updates.
    */
    @available(iOS, introduced: 5.0)
    public func stopmagnetometerUpdates() {
        self.manager.stopMagnetometerUpdates()
        NSLog("Magnetometer Updates Status - Stopped")
    }
    
}
