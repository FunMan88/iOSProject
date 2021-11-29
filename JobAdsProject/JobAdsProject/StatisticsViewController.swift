//
//  StatisticsViewController.swift
//  JobAdsProject
//
//  Created by Andreas Reischl on 29.11.21.
//

import Charts
import UIKit

class StatisticsViewController: UIViewController, ChartViewDelegate {
    
    var barChart = BarChartView()
    
    let datapoints = [1, 5, 3, 10, 7]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barChart.delegate = self
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barChart.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.width)
        barChart.center = view.center
        view.addSubview(barChart)
        
        let dataSet = BarChartDataSet(entries: [
            BarChartDataEntry(x: 1, y: 1),
            BarChartDataEntry(x: 2, y: 5),
            BarChartDataEntry(x: 3, y: 3),
            BarChartDataEntry(x: 4, y: 10),
            BarChartDataEntry(x: 5, y: 7),
        ])
        
        dataSet.colors = ChartColorTemplates.joyful()
        
        let chartData = BarChartData(dataSet: dataSet)
        
        barChart.data = chartData
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
