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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var jobResult: JobAdResult = JobAdResult(results: [])
    
    @IBOutlet weak var jobAdsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        jobAdsTableView.delegate = self
        jobAdsTableView.dataSource = self
        loadJobAds()
    }
    
    func loadJobAds() {
        //print("Currency: " + currency)
        let session = URLSession.shared
        
        //currently only fetching 20 results -> results_per_page
        let url = URL(string: "http://api.adzuna.com/v1/api/jobs/gb/search/1?app_id=" + APIKey.id + "&app_key=" + APIKey.key + "&results_per_page=20&what=javascript%20developer&content-type=application/json")
        //activityIndicator.startAnimating()
        
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
                        //activityIndicator.stopAnimating()
                    }
                }
            })
            
            task.resume()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobResult.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "JobAdCell", for: indexPath) as? JobAdCell else {
            return UITableViewCell()
        }
        
        cell.titleLabel.text = jobResult.results[indexPath.row].title
        cell.descriptionLabel.text = jobResult.results[indexPath.row].description
        cell.minSalaryLabel.text = "Min sal: " + String(jobResult.results[indexPath.row].salary_min)
        cell.maxSalaryLabel.text = "Max cal: " + String(jobResult.results[indexPath.row].salary_max)
        cell.locationLabel.text = "Location: " + jobResult.results[indexPath.row].location.display_name
        cell.companyLabel.text = "Company: " + jobResult.results[indexPath.row].company.display_name
        cell.createdLabel.text = "Created at: " + jobResult.results[indexPath.row].created
        
        return cell
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
        //case contract_type
    }
    
    let id: String
    let title: String
    let description: String
    let salary_min: Double
    let salary_max: Double
    let location: Location
    let salary_is_predicted: String
    // Date might cause a problem
    let created: String
    let category: Category
    let company: Company
    //let contract_type: String
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
        //let contractTypeResult = try container.decode(String.self, forKey: .contract_type)
        
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
        //contract_type = contractTypeResult
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
