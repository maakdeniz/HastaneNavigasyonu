//
//  MapViewController.swift
//  HastaneNavigasyonu
//
//  Created by Mehmet Akdeniz on 4.05.2023.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    
    //MARK: UI Element
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nearestHospitalButton: UIButton!
    
    var searchResultsTableViewController: UITableViewController?
    var searchController: UISearchController!
    var searchResults: [Hospital] = []
    var selectedHospital: Hospital?
    var routeOverlay: MKOverlay?
    var selectedHospitalCoordinate: CLLocationCoordinate2D?
    
    
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        setupMapView()
        setupLocationManager()
        loadHospitalsFromFile()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let coordinate = selectedHospitalCoordinate {
               drawRoute(to: coordinate)
           }
    }
    
    
    //MARK: UIELEMENTACTION
    @IBAction func findNearestHospital(_ sender: UIButton) {
        findClosestHospital()
    }
}




// MARK: - UITableViewDelegate & UITableViewDataSource
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SearchResultCell")
        let hospital = searchResults[indexPath.row]
        cell.textLabel?.text = hospital.name
        cell.detailTextLabel?.text = "Hastane"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hospital = searchResults[indexPath.row]
        
        if let selectedHospital = selectedHospital {
            mapView.deselectAnnotation(selectedHospital, animated: false)
        }
        
        if let routeOverlay = routeOverlay {
            mapView.removeOverlay(routeOverlay)
        }
        
        selectedHospital = hospital
        mapView.setCenter(hospital.coordinate, animated: true)
        drawRoute(to: hospital.coordinate)
        searchController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - MapView
extension MapViewController: MKMapViewDelegate {
    func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Hospital else { return nil }
        
        let identifier = "Hospital"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let rightButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = rightButton
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func drawRoute(to destinationCoordinate: CLLocationCoordinate2D) {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            
            let sourcePlacemark = MKPlacemark(coordinate: mapView.userLocation.coordinate, addressDictionary: nil)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
            
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            let directionRequest = MKDirections.Request()
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            directions.calculate { [unowned self] (response, error) in
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }
                
                let route = response.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let hospital = view.annotation as? Hospital else { return }
        drawRoute(to: hospital.coordinate)
    }
    
    func loadHospitalsFromFile() {
        if let url = Bundle.main.url(forResource: "hospitals", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let hospitals = try JSONDecoder().decode([Hospital].self, from: data)
                mapView.addAnnotations(hospitals)
            } catch {
                print("Error loading hospitals from file: \(error)")
            }
        } else {
            print("Hospitals file not found")
        }
    }
    
    func findClosestHospital() {
        guard let currentLocation = currentLocation else { return }
        
        if let selectedHospital = selectedHospital {
            mapView.deselectAnnotation(selectedHospital, animated: false)
        }
        
        if let routeOverlay = routeOverlay {
            mapView.removeOverlay(routeOverlay)
        }
        
        let hospitals = mapView.annotations.compactMap { $0 as? Hospital }
        let closestHospital = hospitals.min { (hospital1, hospital2) -> Bool in
            let location1 = CLLocation(latitude: hospital1.coordinate.latitude, longitude: hospital1.coordinate.longitude)
            let location2 = CLLocation(latitude: hospital2.coordinate.latitude, longitude: hospital2.coordinate.longitude)
            
            return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
        }
        
        if let closestHospital = closestHospital {
            selectedHospital = closestHospital
            mapView.showAnnotations([closestHospital], animated: true)
            drawRoute(to: closestHospital.coordinate)
        }
    }
}

// MARK: - LocationManager
extension MapViewController: CLLocationManagerDelegate {
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("New location: \(location)") // Bu satırı ekleyin
            currentLocation = location
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
        }
    }
}

class Hospital: NSObject, Codable, MKAnnotation {
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    var title: String? {
        return name
    }
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case latitude
        case longitude
    }
}
