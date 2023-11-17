//
//  ViewController.swift
//  Lab6
//
//  Created by Amarnath  Kathiresan on 2023-11-11.
//

import UIKit
import CoreLocation
import SwiftUI
import WebKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    /* Initialization */
    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var labelCurrentClimate: UILabel!
    @IBOutlet weak var ImageViewCurrentClimate: UIImageView!
    @IBOutlet weak var labelCurrentTemperature: UILabel!
    @IBOutlet weak var labelCurrentHumidity: UILabel!
    @IBOutlet weak var labelCurrentWind: UILabel!
    @IBOutlet weak var svgWebView: WKWebView!
    @IBOutlet weak var loadingView: UIView! {
        didSet {
            loadingView.layer.cornerRadius = 6
        }
    }
    var ImageNameString = ""
    
    // Create a CLLocationManager and assign a delegate
    let locationManager = CLLocationManager()
    
    /* CustomProgressView style */
    struct CustomProgressView: View {
        var body: some View {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                .background(Color(UIColor.systemGray4))
        }
    }
    
    /* CustomProgressView Preview */
    struct CustomProgressView_Previews: PreviewProvider {
        static var previews: some View {
            CustomProgressView()
        }
    }
    
    private let progressView = CustomProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        addSwiftUIView()
        // That's it for the initial setup. Everything else is handled in the
        // locationManagerDidChangeAuthorization method.
        locationManagerDidChangeAuthorization(locationManager)
        
    }
    
    /* locationManagerDidChangeAuthorization function - This is called as soon as the location manager is setup (in viewDidLoad)*/
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            // Request the appropriate authorization based on the needs of the app
            manager.requestWhenInUseAuthorization()
            // manager.requestAlwaysAuthorization()
        case .restricted:
            print("Sorry, restricted")
            // Optional: Offer to take user to app's settings screen
            //openSettingsPage()
        case .denied:
            print("Sorry, denied")
            // Optional: Offer to take user to app's settings screen
            //openSettingsPage()
        case .authorizedAlways, .authorizedWhenInUse:
            // The app has permission so start getting location updates
            print("Permission provided")
            // Request a user’s location once
            locationManager.requestLocation()
        @unknown default:
            print("Unknown status")
        }
    }
    
    /* openSettingsPage Function */
    func openSettingsPage(){
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /* LocationManager didUpdateLocation function for reading current location */
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let location = locations.first {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            // Handle location update
            getWeatherAPI(latitude, longitude)
        }
    }
    
    /* LocationManager didFailWithError function for handling location error */
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Handle failure to get a user’s location
    }
    
    /* downloadImage function for downloading image from URL via URLSession Task */
    func downloadImage(urlstr: String, imageView: UIImageView) {
        let url = URL(string: urlstr)!
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async { // Make sure you're on the main thread here
                imageView.image = UIImage(data: data)
            }
        }
        task.resume()
    }
    
    /* getWeatherAPI function - provides json response from URL via URLSession Task */
    func getWeatherAPI(_ latitude:Double, _ longitude:Double){
        
        //{API key}
        //https://api.openweathermap.org/data/2.5/weather?q=Waterloo,CA&appid=4593f34cf502a5af2da96cd1c811877d
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&exclude=daily&appid=4593f34cf502a5af2da96cd1c811877d&units=metric")
        else {
            return
        }
        let task = URLSession.shared.dataTask(with: url){
            data,response, error in
            //            print (data!)
            //            if let data = data , let string = String(data: data, encoding: .utf8){
            //                print(string)
            //            }
            if let data = data {
                let jsonDecoder = JSONDecoder()
                do{
                    let jsonData = try jsonDecoder.decode(WeatherData.self, from:data)
                    
                    print(jsonData.name)
                    print(jsonData.coord)
                    
                    Task{ @MainActor in
                        /* Displaying values from json data */
                        self.hideSpinner()
                        self.labelLocation.text = jsonData.name
                        self.labelCurrentClimate.text = String(jsonData.weather[0].main)
                        self.labelCurrentTemperature.text = "\(String(format: "%.0f", jsonData.main.temp))°C"
                        self.labelCurrentHumidity.text = "Humidity: \(String(jsonData.main.humidity))%"
                        
                        let speedInMetersPerSec = Measurement(value: Double(jsonData.wind.speed), unit: UnitSpeed.metersPerSecond)
                        let speedInKiloMetersPerHour  = speedInMetersPerSec.converted(to: .kilometersPerHour)
                        self.labelCurrentWind.text = "Wind: \(String(format: "%.2f", speedInKiloMetersPerHour.value )) km/h"
                        self.ImageNameString = jsonData.weather[0].icon
                        let imageURL =  "https://openweathermap.org/img/wn/\(self.ImageNameString)@4x.png"
                        self.downloadImage(urlstr: imageURL, imageView: self.ImageViewCurrentClimate)
                        print(self.labelLocation.text!)
                        print(self.labelCurrentClimate.text!)
                        print(self.labelCurrentTemperature.text!)
                        print(self.labelCurrentHumidity.text!)
                        print(self.labelCurrentWind.text!)
                        //self.getSpeedInKm(String(jsonData.wind.speed))
                        let request = URLRequest(url: self.svgUrlLocal)
                        //let request = URLRequest(url: svgUrlRemote)
                        self.svgWebView.load(request)
                    }
                }catch{
                    print("Error happened")
                }
            }
        }
        task.resume()
        
    }
    
    /* addSwiftUIView function for progressView */
    func addSwiftUIView() {
        let childView = UIHostingController(rootView: progressView)
        addChild(childView)
        loadingView.addSubview(childView.view)
        
        childView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            childView.view.centerXAnchor.constraint(
                equalTo: loadingView.safeAreaLayoutGuide.centerXAnchor),
            childView.view.centerYAnchor.constraint(
                equalTo: loadingView.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        childView.didMove(toParent: self)
        showSpinner()
    }
    
    /* showSpinner function for showing progressView */
    private func showSpinner() {
        loadingView.isHidden = false
        svgWebView.isHidden = true
        self.svgWebView!.isOpaque = false
        self.svgWebView!.backgroundColor = UIColor.clear
        self.svgWebView!.scrollView.backgroundColor = UIColor.clear
    }
    
    /* hideSpinner function for hiding progressView */
    private func hideSpinner() {
        loadingView.isHidden = true
        svgWebView.isHidden = false
    }
    
    /* svgUrlLocal variable to fetch svg file from local */
    var svgUrlLocal: URL {
        let path = Bundle.main.path(forResource: getImageBasedOnCurrentClimateInput(ImageNameString), ofType: "svg")!
        return URL(fileURLWithPath: path)
    }
    
    /* svgUrlRemote variable to fetch svg file from URL */
    var svgUrlRemote: URL {
        let path = "https://www.flaticon.com/svg/static/icons/svg/3874/3874453.svg"
        return URL(string: path)!
    }
    
    /* getImageBasedOnCurrentClimateInput function to fetch svg file name matching json weather data */
    func getImageBasedOnCurrentClimateInput(_ imageName:String) -> String{
        switch imageName {
        case "01d":
            return "sunriseAlt"
        case "01n":
            return "moon"
        case "02d":
            return "cloudFogSunAlt"
        case "02n":
            return "cloudFogMoonAlt"
        case "03d":
            return "cloudFogSunAlt"
        case "03n":
            return "cloudFogMoonAlt"
        case "04d":
            return "cloudSun"
        case "04n":
            return "cloudMoon"
        case "09d":
            return "cloudDrizzleSunAlt"
        case "09n":
            return "cloudDrizzleMoonAlt"
        case "10d":
            return "cloudRainSunAlt"
        case "10n":
            return "cloudRainMoonAlt"
        case "11d":
            return "cloudLightningSun"
        case "11n":
            return "cloudLightningMoon"
        case "13d":
            return "cloudSnowSunAlt"
        case "13n":
            return "cloudSnowMoonAlt"
        case "50d":
            return "wind"
        case "50n":
            return "wind"
        default:
            return "sunsetAlt"
        }
    }
    
    /* getSpeedInKm function */
    //    func getSpeedInKm(_ distanceInMiles:String) -> String{
    //        let distanceInMeters: Double = Double(distanceInMiles)!
    //        let formatter = MeasurementFormatter()
    //        formatter.unitStyle = .medium // adjust according to your need
    //        let distance = Measurement(value: distanceInMeters, unit: UnitLength.meters)
    //
    //        formatter.locale = Locale(identifier: "en_UK")
    //        let distanceInMiles = formatter.string(from: distance) // 1.462 mi
    //        formatter.locale = Locale(identifier: "en_FR")
    //        let distanceInKMs = formatter.string(from: distance) // 2,353 km
    //        print(distanceInMiles)
    //        print(distanceInKMs)
    //        return distanceInKMs
    //    }
}

