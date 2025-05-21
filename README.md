Utilities: 

  Step Analyzer
  
Step Analyzer is no longer used but offers another equation and way of calculating the user's stride length. There are three functions, startAnalyzing(), stopAnalyzing(), and addStepLength(_ length: Float). The function startAnalyzing() contains the calculation for the user's stride length and calls addStepLength() to add the stride length to the array of all the stride lengths. The function stopAnalyzing(), stops the device's motion updates, which would be used when the user stops their walk. Lastly, the function addStepLength(_ length: Float), which is called at the end of startAnalyzing(), adds the input stride length to the array of all the stride lengths. It then calculates the average step length with a moving window of values. 

  Step Manager
  
Step Manager is used for checking if the current stride length and stride speed are within the deviants set before the walk, checked against the values calculated in the calibration step, and preparing the haptic feedback, a buzz, for the user. The first function checkForStepOutliers(stepLength: Float), is called from within the step tracker class. The function checks if the difference between the passed in step length value and the target step length value is less than the step length tolerance set before the users walk. If it is not, the function will return false, and if it is the function will return true. The next function, checkForSpeedOutliers(speed: Float), is called from within the step tracker class. The function checks if the difference between the passed in step speed value and the target step speed value is less than the step speed tolerance set before the users walk. If it is not, the function will return false, and if it is the function will return true. The next function triggerWarning(), is called within the step tracker class. This function then calls the private buzz function. The next function prepareHaptics() is a private function within Step manager. This function is called in the init() function for step managers. It is responsible for initializing the haptic engine on an iOS device so that your app can generate haptic feedback (e.g., vibration patterns) later. It checks if haptic feedback is supported, initializes the haptic engine, and then starts the engine. The last function, buzz(), is a private function within Step manager. This function creates and plays a custom haptic pattern using the iOS Core Haptics framework. It generates a short burst of haptic feedback made up of three quick taps (transient haptics) with varying intensity and sharpness, spaced out slightly over time. It defines It defines three transient haptic events (short, tap-like feedback) using CHHapticEvent: pulse 1 = Intensity: 1.0 (strong), Sharpness: 1.0 (crisp), Time: immediately (0.0s), pulse 2 = Intensity: 0.6 (medium strength), Sharpness: 0.5 (smoother), Time: after 0.2 seconds, and pulse 3 = Intensity: 0.9 (strong), Sharpness: 0.9 (sharp), Time: after 0.4 seconds. 

  Step Tracker
  
The StepTracker class uses CoreMotion to detect steps and calculate stride length and walking speed in real time. It integrates data from the accelerometer and gyroscope to estimate step counts, stride lengths, and walking speed, while also detecting outliers based on customizable thresholds. The class uses both Core Motion's CMPedometer and CMMotionManager to handle step events and motion data respectively. It tracks various metrics like total steps, total distance, step durations, stride lengths, and walking speed, and it flags warnings when too many outliers are detected in recent step data. It also includes logic to reset the data, start and stop tracking sessions, and calculate average values.

Here is a list of all the function and their uses:

  startTracking() function initializes motion and pedometer updates, records the start time, and begins collecting accelerometer and gyroscope data to detect steps and calculate stride metrics. 
  
  stopTracking() function stops all ongoing motion updates and resets step-related counters and lists, effectively halting tracking and clearing session data.

  reset() clears all step-related data without stopping the sensors. Useful for restarting a session while keeping the system running.

  startUpdates() is called when the user starts their walk and it begins collecting motion data from the accelerometer and gyroscope, preparing the system to detect steps in real time.
  
  processAcceleration() processes incoming accelerometer data to identify peaks that may correspond to steps, while filtering noise and tracking time between peaks.
  
  addStepData() records each detected step’s stride length and speed, updating the history used to compute moving averages and detect outliers.
  
  calculateStepLength() calculates the step length using either the peak acceleration method or a raw sensor fusion method, depending on the configuration

The following functions are used in a second way to calculate the user's stride length. While they are not used in the output of the app, they provide an additional way to obtain the users stride length using the raw accelerometer and gyroscope data. These calculations were originally used to find the most accurate stride length calculation. 

  registerStep() is called whenever a step is detected. It calculates and stores stride length, walking speed, and duration between steps using both raw sensor fusion and peak acceleration methods. It also handles outlier detection and vibration feedback if thresholds are exceeded
  
  calculateAverages() computes the moving average of stride length and walking speed over the most recent steps to provide real-time trend analysis
  
  calculateStrideLengthRawSensorFusion() estimates stride length using angular velocity data from the gyroscope and the time between steps, offering an alternative to the peak-based method.
  
  registerStepWithPeakAcceleration() finalizes a step when using the peak acceleration method by calculating the stride length and logging it with a timestamp.
  
  updatePeakAcceleration() tracks the maximum acceleration value between detected steps to aid in estimating stride length with the peak method.
  
  calibrateEmpiricalK() is used to calibrate the constant used in the empirical stride length formula, enabling personalized accuracy based on known stride measurements.

  Location Manager
  
Location Manager is used for tracking the total distance during the user walk using the device's GPS functionality. It used CLLocationManagerDelegate protocol, enabling it to receive and process real-time location updates with the highest possible accuracy (kCLLocationAccuracyBest). Upon initialization, it requests permission to access the user's location data while the app is in use. When start() is called, it resets the total distance and clears any previously stored location, then begins listening for new location updates. Each time a location update is received via the locationManager(_:didUpdateLocations:) delegate method, it calculates the distance between the last known location and the new one. This incremental distance is then added to totalDistance. The stop() function halts location updates entirely, while pause() and resume() allow temporary suspension and continuation of tracking without resetting the accumulated distance. If location services fail, the locationManager(_:didFailWithError:) method will print the error to help with debugging.

Views: 

  Content View
  
Content view is the home screen of the app. On this screen, you can see “Stride Length Tracking” which is the name of the app, all of the variables you can set within the app, a button that takes you to the calibration step and a button that takes you to start your walk, and the target stride length and walking step speed displayed, either calibrated in the calibration step or inputted by the user. The variables you can set within the app are: the users target stride length (inches), number of steps to calculate your average stride length with, allowed number of outlier steps, allowed number of outlier step speeds, stride deviation tolerance (inches), and speed deviation tolerance (inches / second). Since the app also tracks the distance you walk, a pop-up will appear asking you if you want to allow the app to use your location, please press always allow or allow while using.  After your walk is finished, the content view screen will display a new set of variables, as a summary of the user's walk. These new variables include: Final Step Cunt, Percentage of Good Steps, Walk Duration, Walk Distance, Final Average Stride Length (inches), and Final Average Walking Speed (inches / second).  

  Tracking View 
  
Tracking View is what values are displayed while the user is walking. At the top of the screen, it will indicate if the user is walking, not walking, or paused, which changes when the user presses the start / stop walk and pause / resume walk button. When the user is not walking, the metrics that are displayed on the screen are Target Step Length (inches), Target Walking Speed (inches/second), Total Steps, Distance, Walk Duration, and Average Stride Length (inches). When the user is walking, they have the option to either pause or stop their walk. Pausing their walk will allow them to stop their walk and the app will stop taking measurements. When the user resumes their walk, measurements will be taken again and their walk will continue. Stopping their walk will end the walk and take them back to the home screen. 

  Calibration View
  
The Calibration View is the first screen that appears after the user taps the "Calibration Step" button. Initially, it prompts the user with the message “Please Walk 10 Steps,” displays the number of steps taken so far, and presents a "Start Calibration" button. Pressing this button transitions the user to the calibration-in-progress view. Once calibration is complete, the view updates to show a confirmation message, the calculated target step length, the calculated average walking speed, and two options: to redo the calibration or to accept the results with an “OK” button. This view includes three main functions: startCalibration(), finishCalibration(), and redoCalibration(). The startCalibration() function performs stride and speed calculations similar to those in the StepTracker class, but keeping a localized copy allows for these values to be determined specifically within the calibration flow. The finishCalibration() function saves the calculated target stride length, step speed, and calibrateEmpiricalK values into the StepTracker and StepManager classes, ensuring that the calibrated data is used throughout the app. It also notifies the user that calibration has been successfully completed. The redoCalibration() function resets all relevant values to zero, allowing the user to start the calibration process over if needed. 

  Calibration In Progress View
  
The CalibrationInProgressView SwiftUI class represents the screen shown while the user's walking steps are being tracked during the calibration phase. This view is connected to both the StepManager and StepTracker classes, enabling it to update dynamically as step data changes. When the view appears, it automatically starts step tracking by calling startTracking(). The interface displays a prominent title, the number of steps taken, and a red “Stop Calibration” button. Pressing this button stops the calibration by calling stopTracking() and dismisses the current view, returning the user to the previous calibration screen. The purpose of this view is to visually guide the user through the walking phase of calibration while tracking their step count in real time. 
