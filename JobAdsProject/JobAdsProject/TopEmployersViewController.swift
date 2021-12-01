//
//  TopEmployersViewController.swift
//  JobAdsProject
//
//  Created by Andreas Reischl on 01.12.21.
//

import UIKit

class TopEmpCell : UITableViewCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var vacanciesLabel: UILabel!
}

class TopEmployersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var jobTitle : String = ""
    var country : String = ""
    
    var topCompanyResult: TopCompanyResult = TopCompanyResult(leaderboard: [])
    
    @IBOutlet weak var jobTitleTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var topEmpTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.hidesWhenStopped = true
        topEmpTableView.delegate = self
        topEmpTableView.dataSource = self
    }
    
    @IBAction func searchResultsButtonClicked(_ sender: Any) {
        jobTitle = (jobTitleTextField.text ?? "").replacingOccurrences(of: " ", with: "%20")
        country = (countryTextField.text ?? "").replacingOccurrences(of: " ", with: "%20")
        
        loadEmployerData()
    }
    
    func loadEmployerData() {
        let session = URLSession.shared
        let id: String = "app_id=" + APIKey.id
        let key : String = "&app_key=" + APIKey.key
        let location : String = "&location0=" + country
        let filter : String = "&what=" + jobTitle

        let apiStart : String = "http://api.adzuna.com/v1/api/jobs/" + country + "/top_companies?" + id
        let contentType : String = "&content-type=application/json"
        
        let apiRequest : String = apiStart + key +  filter + contentType
        
        let url = URL(string: apiRequest)
        
        if let url = url {
            activityIndicator.startAnimating()
            
            let task = session.dataTask(with: url, completionHandler: { [self]data, response, error in
                if let data = data {
                    let result = try? JSONDecoder().decode(TopCompanyResult.self, from: data)
                                        
                    guard let topCompRes = result
                    else {
                        return;
                    }

                    self.topCompanyResult = topCompRes
                    
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        topEmpTableView.reloadData()
                    }
                }
            })
            
            task.resume()
        }
    }
    
    // MARK: - Table view functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topCompanyResult.leaderboard.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TopEmpCell", for: indexPath) as? TopEmpCell else {
            return UITableViewCell()
        }
        
        cell.positionLabel.text = "#" + String(indexPath.row + 1)
        cell.companyLabel.text = topCompanyResult.leaderboard[indexPath.row].canonical_name
        cell.vacanciesLabel.text = "Vacancies: " + String(topCompanyResult.leaderboard[indexPath.row].count)
        
        return cell
    }
}

struct TopCompanyResult {
    var leaderboard: [Leaderboard]
    
    enum CodingKeys: String, CodingKey {
        case leaderboard
    }
}

extension TopCompanyResult : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let leaderboards = [Leaderboard]()
        
        let decodedObject = try container.decode([Leaderboard].self, forKey: .leaderboard)
            leaderboard = decodedObject
    }
}

// MARK: - Decodables

struct Leaderboard {
    let count: Int
    let canonical_name: String
    
    enum CodingKeys: String, CodingKey {
        case count
        case canonical_name
    }
}

extension Leaderboard : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let countRes = try container.decode(Int.self, forKey: .count)
        
        let canNameRes = try container.decode(String.self, forKey: .canonical_name)
        
        count = countRes
        canonical_name = canNameRes
    }
}
