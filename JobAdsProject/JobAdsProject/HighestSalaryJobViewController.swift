//
//  HighestSalaryJobViewController.swift
//  JobAdsProject
//
//  Created by Andreas Reischl on 01.12.21.
//

import UIKit
import MapKit

class HighestSalaryJobViewController: UIViewController {
    var highestSalaryAd: JobAd?
    var highestSalary: Double = 0
    
    @IBOutlet weak var controllerTitleLabel: UILabel!
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var jobDescriptionLabel: UILabel!
    @IBOutlet weak var minSalLabel: UILabel!
    @IBOutlet weak var maxSalLabel: UILabel!
    @IBOutlet weak var avgSalLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var mkMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        jobTitleLabel.text = highestSalaryAd?.title ?? "No Job Title"
        jobDescriptionLabel.text = highestSalaryAd?.description ?? "No description available"
        minSalLabel.text = "Minimum Salary: " + String(highestSalaryAd?.salary_min ?? 0)
        maxSalLabel.text = "Maximum Salary: " + String(highestSalaryAd?.salary_max ?? 0)
        avgSalLabel.text = "Average Salary: " + String(highestSalary)
        companyLabel.text = "Company: " + (highestSalaryAd?.company.display_name ?? "No company info available")
        
        if let lon = highestSalaryAd?.longitude {
            if let lat = highestSalaryAd?.latitude {
                let initialLocation = CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
                
                mkMapView.centerToLocation(initialLocation)
                
                let companyLocation : CompanyLocation = CompanyLocation(title: highestSalaryAd?.title, locationName: highestSalaryAd?.company.display_name, coordinate: initialLocation.coordinate)
                
                mkMapView.addAnnotation(companyLocation)
            }
        }
    }
}

private extension MKMapView {
  func centerToLocation(
    _ location: CLLocation,
    regionRadius: CLLocationDistance = 1000
  ) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}

class CompanyLocation: NSObject, MKAnnotation {
    let title: String?
    let locationName: String?
    let coordinate: CLLocationCoordinate2D
    
    init(
       title: String?,
       locationName: String?,
       coordinate: CLLocationCoordinate2D
     ) {
       self.title = title
       self.locationName = locationName
       self.coordinate = coordinate

       super.init()
     }

     var subtitle: String? {
       return locationName
     }
}
