//
//  ViewController.swift
//  JobAdsProject
//
//  Created by Andreas Reischl on 29.11.21.
//

import UIKit

class JobAdCell : UITableViewCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var minSalaryLabel: UILabel!
    @IBOutlet weak var maxSalaryLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
}

public class JobTitleSearchController : UISearchController {
    public var jobTitleSearchBar = UISearchBar()

    override public var searchBar: UISearchBar {
        get {
            return jobTitleSearchBar
        }
    }

}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
   
    var jobResult: JobAdResult = JobAdResult(results: [])
    
    @IBOutlet weak var jobAdsTableView: UITableView!
    @IBOutlet weak var jobTitleSearchBar: UISearchBar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let searchController = JobTitleSearchController()
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.hidesWhenStopped = true
        
        jobAdsTableView.delegate = self
        jobAdsTableView.dataSource = self
        
        searchController.jobTitleSearchBar = jobTitleSearchBar
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        loadJobAds(jobTitle: nil)
    }
    
    func loadJobAds(jobTitle: String?) {
        print("job title: " + (jobTitle ?? ""))
        let session = URLSession.shared
        
        let apiStart = "http://api.adzuna.com/v1/api/jobs/gb/search/1?app_id="
        
        //currently only fetching 30 results -> results_per_page
        let url = URL(string: apiStart + APIKey.id + "&app_key=" + APIKey.key + "&results_per_page=30&what=" + (jobTitle ?? "") + "&content-type=application/json")
        activityIndicator.startAnimating()
        
        if let url = url {
            let task = session.dataTask(with: url, completionHandler: { [self]data, response, error in
                print(response?.description ?? "")
                if let data = data {
                    print(String(decoding: data, as: UTF8.self))
                    let result = try? JSONDecoder().decode(JobAdResult.self, from: data)
                    print(result ?? [])
                    
                    guard let jobRes = result
                    else {
                        return;
                    }

                    self.jobResult = jobRes
                    
                    DispatchQueue.main.async {
                        jobAdsTableView.reloadData()
                        activityIndicator.stopAnimating()
                    }
                }
            })
            
            task.resume()
        }
    }

    // MARK: - Table View functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobResult.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "JobAdCell", for: indexPath) as? JobAdCell else {
            return UITableViewCell()
        }
        
        // some date formatting for the api date string to apply to the German date form
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZ"
        let dateString = jobResult.results[indexPath.row].created
        let newDate = dateFormatter.date(from: dateString)
        dateFormatter.dateFormat = "d.M.yyyy HH:mm"
        var correctDateString = "Unknown"
        
        if let date = newDate {
            correctDateString = dateFormatter.string(from: date)
        }
        
        cell.titleLabel.text = jobResult.results[indexPath.row].title
        cell.descriptionLabel.text = jobResult.results[indexPath.row].description
        cell.minSalaryLabel.text = "Min sal: " + String(jobResult.results[indexPath.row].salary_min)
        cell.maxSalaryLabel.text = "Max cal: " + String(jobResult.results[indexPath.row].salary_max)
        cell.locationLabel.text = "Location: " + jobResult.results[indexPath.row].location.display_name
        cell.companyLabel.text = "Company: " + jobResult.results[indexPath.row].company.display_name
        cell.createdLabel.text = "Created at: " + correctDateString
        
        return cell
    }
    
    // MARK: - Search Bar functions
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // in an http query spaces have to be replaced using '%20'
        var searchText = searchBar.text
        searchText = searchText?.replacingOccurrences(of: " ", with: "%20")
        loadJobAds(jobTitle: searchText)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        print("search update")
    }
}

// MARK: - Decodables

struct JobAdResult {
    //only interested in results
    enum CodingKeys: String, CodingKey {
        case results
    }
    
    let results: [JobAd]
}

extension JobAdResult : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let jobAdResult = try container.decode([JobAd].self, forKey: .results)
        
        results = jobAdResult
    }
}

struct JobAd {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case salary_min
        case salary_max
        case location
        case salary_is_predicted
        case created
        case category
        case company
    }
    
    let id: String
    let title: String
    let description: String
    let salary_min: Double
    let salary_max: Double
    let location: Location
    let salary_is_predicted: String
    let created: String
    let category: Category
    let company: Company
}

extension JobAd : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let idResult = try container.decode(String.self, forKey: .id)
        let titleResult = try container.decode(String.self, forKey: .title)
        let descResult = try container.decode(String.self, forKey: .description)
        let salMinResult = try container.decode(Double.self, forKey: .salary_min)
        let salMaxResult = try container.decode(Double.self, forKey: .salary_max)
        let locationResult = try container.decode(Location.self, forKey: .location)
        let salIsPredResult = try container.decode(String.self, forKey: .salary_is_predicted)
        let createdResult = try container.decode(String.self, forKey: .created)
        let categoryResult = try container.decode(Category.self, forKey: .category)
        let companyResult = try container.decode(Company.self, forKey: .company)
        
        id = idResult
        title = titleResult
        description = descResult
        salary_min = salMinResult
        salary_max = salMaxResult
        location = locationResult
        salary_is_predicted = salIsPredResult
        created = createdResult
        category = categoryResult
        company = companyResult
    }
}

struct Location {
    enum CodingKeys: String, CodingKey {
        case area
        case display_name
    }
    
    let area: [String]
    let display_name: String
}

extension Location : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let areaResult = try container.decode([String].self, forKey: .area)
        let nameResult = try container.decode(String.self, forKey: .display_name)
        
        area = areaResult
        display_name = nameResult
    }
}

struct Category {
    enum CodingKeys: String, CodingKey {
        case label
        case tag
    }
    
    let label: String
    let tag: String
}

extension Category : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let labelResult = try container.decode(String.self, forKey: .label)
        let tagResult = try container.decode(String.self, forKey: .tag)
        
        label = labelResult
        tag = tagResult
    }
}

struct Company {
    enum CodingKeys: String, CodingKey {
        case display_name
    }
    
    let display_name: String
}

extension Company : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let nameResult = try container.decode(String.self, forKey: .display_name)
        
        display_name = nameResult
    }
}
