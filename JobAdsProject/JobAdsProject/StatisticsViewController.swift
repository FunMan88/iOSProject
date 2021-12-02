//
//  StatisticsViewController.swift
//  JobAdsProject
//
//  Created by Andreas Reischl on 29.11.21.
//

import Charts
import UIKit

final class SalDistAxisValueFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(value * 10) + "k"
    }
}

class StatisticsViewController: UIViewController, ChartViewDelegate {
    
    var barChart = BarChartView()
    
    let datapoints = [1, 5, 3, 10, 7]
    
    var country : String = "gb"
    var jobTitle : String = "Java%20Developer"
    
    var salaryDistributionResult: SalaryDistributionResult = SalaryDistributionResult(histogram: Histogram(distributions: []))
    
    var salaryResult : MonthlyAverageSalaryResult = MonthlyAverageSalaryResult(month: SalaryResult(monthlySalData: []))
    
    @IBOutlet weak var salDistView: UIView!
    
    @IBOutlet weak var jobTitleTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var showResultsButton: UIButton!
    @IBOutlet weak var salDistLabel: UILabel!
    @IBOutlet weak var avgSalLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barChart.delegate = self
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barChart.frame = CGRect(x: 0, y: 0, width: salDistView.frame.size.width, height: salDistView.frame.size.width)
        barChart.xAxis.valueFormatter = SalDistAxisValueFormatter()
        salDistView.addSubview(barChart)
    }
    
    @IBAction func showResultsButtonClicked(_ sender: Any) {
        country = countryTextField.text ?? ""
        jobTitle = (jobTitleTextField.text ?? "").replacingOccurrences(of: " ", with: "%20")
        
        salDistLabel.text = "Salary Distribution"
        loadSalaryDistributionData()
        loadAverageSalaryData()
    }
    
    
    func fillChartWithSalaryDistributionData() {
        var dataSetEntries : [BarChartDataEntry] = [BarChartDataEntry]()
        salaryDistributionResult.histogram.distributions.forEach{dist in
            dataSetEntries.append(BarChartDataEntry(x: (Double(dist.scale) ?? 0) / 10000, y: Double(dist.count)))
        }
        
        let dataSet =  BarChartDataSet(entries: dataSetEntries, label: "Salary Distribution")
        
        dataSet.colors = ChartColorTemplates.joyful()

        let chartData = BarChartData(dataSet: dataSet)
        
        barChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        
        barChart.data = chartData
    }
    
    func calculateAverageSalary() {
        salaryResult.month.monthlySalData.sort { SalaryMonthData1, SalaryMonthData2 in
            return SalaryMonthData1.date < SalaryMonthData2.date
        }
                
        let avgSal : Double = salaryResult.month.monthlySalData.last?.avgSalary ?? 0
        avgSalLabel.text = "Average Salary: " + String(avgSal)
    }
    
    func loadSalaryDistributionData() {
        let session = URLSession.shared
        let id: String = "app_id=" + APIKey.id
        let key : String = "&app_key=" + APIKey.key
        let location : String = "&location0=" + country
        let filter : String = "&what=" + jobTitle

        let apiStart : String = "http://api.adzuna.com/v1/api/jobs/" + country + "/histogram?" + id
        let contentType : String = "&content-type=application/json"
        
        let apiRequest : String = apiStart + key +  filter + contentType
        
        let url = URL(string: apiRequest)
        activityIndicator.startAnimating()
        
        if let url = url {
            let task = session.dataTask(with: url, completionHandler: { [self]data, response, error in
                if let data = data {
                    let result = try? JSONDecoder().decode(SalaryDistributionResult.self, from: data)
                    
                    guard let salDistRes = result
                    else {
                        return;
                    }

                    self.salaryDistributionResult = salDistRes
                    
                    DispatchQueue.main.async {
                        fillChartWithSalaryDistributionData()
                        activityIndicator.stopAnimating()
                    }
                }
            })
            
            task.resume()
        }
    }
    
    func loadAverageSalaryData() {
        let session = URLSession.shared
        let id: String = "app_id=" + APIKey.id
        let key : String = "&app_key=" + APIKey.key
        let location : String = "&location0=" + country
        let filter : String = "&what=" + jobTitle

        let apiStart : String = "http://api.adzuna.com/v1/api/jobs/" + country + "/history?" + id
        let contentType : String = "&content-type=application/json"
        
        let apiRequest : String = apiStart + key +  filter + contentType
        
        let url = URL(string: apiRequest)
        
        if let url = url {
            let task = session.dataTask(with: url, completionHandler: { [self]data, response, error in
                if let data = data {
                    let result = try? JSONDecoder().decode(MonthlyAverageSalaryResult.self, from: data)
                    
                    guard let salAvgRes = result
                    else {
                        return;
                    }

                    self.salaryResult = salAvgRes
                    
                    DispatchQueue.main.async {
                        calculateAverageSalary()
                    }
                }
            })
            
            task.resume()
        }
    }
}

// MARK: - Decodables for Distribution

struct SalaryDistributionResult {
        enum CodingKeys: String, CodingKey {
            case histogram
        }
        
        let histogram: Histogram
}

extension SalaryDistributionResult : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let histResult = try container.decode(Histogram.self, forKey: .histogram)
        
        histogram = histResult
    }
}

struct Histogram {
    let distributions: [DistributionUnit]
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        var doubleValue: Double?
        
        init?(intValue: Int) {
            self.intValue = intValue
            //self.doubleValue = Double(intValue)
            self.stringValue = String(intValue)
        }
        
        init?(doubleValue: Double) {
            self.doubleValue = doubleValue
            //self.intValue = Int(doubleValue)
            self.stringValue = String(doubleValue)
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
    }
}

extension Histogram : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        var tempDistributions = [DistributionUnit]()
        
        for key in container.allKeys {
            let decodedObject = try container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)
            tempDistributions.append(DistributionUnit(scale: key.stringValue, count: decodedObject))
        }
        
        distributions = tempDistributions
    }
}

struct DistributionUnit : Decodable {
    let scale: String
    let count: Int
    
    init(scale: String, count: Int) {
        self.scale = scale
        self.count = count
    }
}

// MARK: Decodables for Average Monthly Salary

struct MonthlyAverageSalaryResult {
    enum CodingKeys: String, CodingKey {
        case month
    }
    
    var month: SalaryResult
}

extension MonthlyAverageSalaryResult : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let salResult = try container.decode(SalaryResult.self, forKey: .month)
        
        month = salResult
    }
}

struct SalaryResult {
    var monthlySalData: [SalaryMonthData]

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        var doubleValue: Double?
        
        init?(intValue: Int) {
            return nil
        }
        
        init?(doubleValue: Double) {
            return nil
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
    }
}

extension SalaryResult : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        var salMonthData = [SalaryMonthData]()
        
        for key in container.allKeys {
            let decodedObject = try container.decode(Double.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)
            salMonthData.append(SalaryMonthData(date: key.stringValue, avgSalary: decodedObject))
        }
        
        monthlySalData = salMonthData
    }
}

struct SalaryMonthData : Decodable {
    
    let date: String
    let avgSalary: Double
    
    init(date: String, avgSalary: Double) {
        self.date = date
        self.avgSalary = avgSalary
    }
}

