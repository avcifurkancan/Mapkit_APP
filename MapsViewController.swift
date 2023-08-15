//
//  ViewController.swift
//  MapKitUygulamasi
//
//  Created by Furkancan Avcı on 25.07.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData


class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var txtIsim: UITextField!
    @IBOutlet weak var txtNot: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenID : UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        //konum kalitesi
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //kullanıcı izini
        locationManager.requestWhenInUseAuthorization()
        //her konum güncellemesinde
        locationManager.startUpdatingLocation()
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                             action: #selector(konumSec(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != ""{
            //boş ise veri çek
            if let uuidString = secilenID?.uuidString{
               
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0{
                        for sonuc in sonuclar as! [NSManagedObject]{
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubTitle = not
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                        annotationLatitude = latitude
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            
                                            txtIsim.text = annotationTitle
                                            txtNot.text = annotationSubTitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate,
                                                                            span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    print("Hata")
                }
                
                
            }
        }
        else{
            //yeni veri ekle
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
        let reuseID = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        
        if pinView == nil{
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != ""{
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarkdizisi, hata in
                if let placemarks = placemarkdizisi {
                    if placemarks.count > 0 {
                        let yeniPlaceMark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlaceMark)
                        item.name = self.annotationTitle
                        let launchOption = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOption)
                    }
                }
            }
            
            
        }
    }
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKordinat.latitude
            secilenLongitude = dokunulanKordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKordinat
            annotation.title = txtIsim.text
            annotation.subtitle = txtNot.text
            mapView.addAnnotation(annotation)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       // print(locations[0].coordinate.latitude)
       // print(locations[0].coordinate.longitude)
        
        if secilenIsim == ""{
            //konum yeri
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude,
                                                  longitude: locations[0].coordinate.longitude)
            //uzaklık ayarı
            let span = MKCoordinateSpan(latitudeDelta: 0.05,
                                        longitudeDelta: 0.05)
            //region ayarı
            let region = MKCoordinateRegion(center: location,
                                            span: span)
            
            //konumda harita açma
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func Kaydet(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(txtIsim.text, forKey: "isim")
        yeniYer.setValue(txtNot.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Kayıt Edildi.")
        } catch{
            print("Hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    


}
