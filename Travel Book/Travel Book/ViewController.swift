//
//  ViewController.swift
//  Travel Book
//
//  Created by Kadir Duraklı on 3.08.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mapView: MKMapView!

    var locationManager = CLLocationManager()
    var selectedLongitude = Double()
    var selectedLatitude = Double()
    var selectedName = ""
    var selectedID : UUID?
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    override func viewDidLoad() {
        nameText.text = ""
        commentText.text = ""
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //Tahmin keskinliği
        locationManager.requestWhenInUseAuthorization() //Konuma erişim izni isteme
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer: ))) //Basılı tutulduğunda pinleme için oluşturulan jest algılayıcı
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedName != "" {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
            
            fetchRequest.returnsObjectsAsFaults = false
            
            let idString = selectedID?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            
            do {
                let results = try context.fetch(fetchRequest)
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String,
                       let comment = result.value(forKey: "comment") as? String,
                       let longitude = result.value(forKey: "longitude") as? Double,
                       let latitude = result.value(forKey: "latitude") as? Double  {
                        nameText.text = name
                        annotationTitle = name
                        commentText.text = comment
                        annotationSubtitle = comment
                        annotationLongitude = longitude
                        annotationLatitude = latitude
                        let annotation = MKPointAnnotation()
                        annotation.title = annotationTitle
                        annotation.subtitle = annotationSubtitle
                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                        annotation.coordinate = coordinate
                        mapView.addAnnotation(annotation)
                        nameText.text = annotationTitle
                        commentText.text = annotationSubtitle
                        locationManager.stopUpdatingLocation()
                        
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                    }
                }
            } catch {
                print("failed")
            }
        }
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            selectedLongitude = touchedCoordinates.longitude
            selectedLatitude = touchedCoordinates.latitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinview = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        if pinview == nil {
            pinview = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinview?.canShowCallout = true
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinview?.rightCalloutAccessoryView = button
        }
        
        else {
            pinview?.annotation = annotation
        }
        
        return pinview
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //Konumun enlem ve boylamını belirtme
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //Zoom seviyesi
            let region = MKCoordinateRegion(center: location, span: span) //
            mapView.setRegion(region, animated: true)
        } else {
            
        }
    }
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
        newLocation.setValue(selectedLongitude, forKey: "longitude")
        newLocation.setValue(selectedLatitude, forKey: "latitude")
        newLocation.setValue(UUID(), forKey: "id")
        newLocation.setValue(nameText.text, forKey: "name")
        newLocation.setValue(commentText.text, forKey: "comment")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("failed")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newLocation"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}

