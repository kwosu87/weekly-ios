//
//  MasterViewController.swift
//  Weekly
//
//  Created by Wooseong Kim on 2015. 7. 31..
//  Copyright © 2015년 Wooseong Kim. All rights reserved.
//

import UIKit
import CoreData
import SnapKit

class MasterViewController: UIViewController, NSFetchedResultsControllerDelegate, UIToolbarDelegate, SwipeViewDataSource,
    SwipeViewDelegate, UITableViewDataSource, UITableViewDelegate, TodoPointCellDelegate {
    
    let DAY_LABEL_INSET: CGFloat = 10
    
    var toolbar: UIToolbar!
    var naviHairlineImageView: UIImageView?
    var dayOfWeekLabels: [UILabel]!
    var swipeView: SwipeView!
    var previousSwipeViewIndex: Int = 0
    var tableView: UITableView!
    
    var selectedYear: Int = 0
    var selectedWeekOfYear: Int = 0
    var selectedWeekdayIndex: Int = 0 // 1 = Sunday, 7 = Saturday 에서 -1 처리함
    var selectedDayLabel: UILabel!
    
    var visionTodoPoints = [TodoPoint]()
    var dailyTodoPoints = [TodoPoint]()
    var weeklyTodoPoints = [TodoPoint]()
    
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
//        let backButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
//        self.navigationItem.leftBarButtonItem = backButtonItem

        // Model
        initDate()
        
        // UI
        initAddButton()
        initToolbar()
        initNavigationBar()
        initDayOfWeekLabels()
        initSwipeView()
        initSelectedDayLabel()
        
        // TODO: 나중에 지워야할 더미 데이터
//        addDummys()
        initTableView()
    }
    
    func initDate() {
        // 오늘 날짜를 구해 요일 번호를 구한다
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let components = calendar.components([.Year, .WeekOfYear, .Weekday], fromDate: NSDate())
        selectedYear = components.year
        selectedWeekOfYear = components.weekOfYear
        selectedWeekdayIndex = components.weekday - 1
    }

    func initAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewTodoPoint:")
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func initToolbar() {
        toolbar = UIToolbar()
        self.view.addSubview(toolbar)
        toolbar.layer.zPosition = 2
        toolbar.snp_makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo((self.topLayoutGuide as AnyObject as! UIView).snp_bottom)
        }
        toolbar.delegate = self;
    }
    
    func initNavigationBar() {
        // 네비게이션 바 아래쪽 툴바를 붙이기에, 네비바 아래쪽 줄을 안보이게 해서 툴바와 같은 뷰처럼 보이게 처리
        let naviBarWidth = self.navigationController?.navigationBar.frame.size.width
        for naviSubView in self.navigationController!.navigationBar.subviews {
            for subView in naviSubView.subviews {
                let subViewWidth = subView.bounds.size.width
                let subViewHeight = subView.bounds.size.height
                if subView.isKindOfClass(UIImageView) && subViewWidth == naviBarWidth && subViewHeight < 2 {
                    self.naviHairlineImageView = subView as? UIImageView
                }
            }
        }
    }
    
    func initDayOfWeekLabels() {
        let screenWidth = UIScreen.mainScreen().applicationFrame.width
        let labelWidth = screenWidth / 7;
        
        // 디바이스 width를 7로 나누어서 일~토 까지 width를 설정해주고, horizontal로 붙인다.
        dayOfWeekLabels = [UILabel]();
        
        for index in 0...6 {
            let dayOfWeekLabel = UILabel()
            dayOfWeekLabel.layer.zPosition = 4
            dayOfWeekLabel.numberOfLines = 1
            dayOfWeekLabel.textAlignment = .Center;
            dayOfWeekLabel.text = getDayOfWeekString(index)
            dayOfWeekLabel.font = UIFont.systemFontOfSize(11)

            self.view.addSubview(dayOfWeekLabel)
            dayOfWeekLabels.append(dayOfWeekLabel)
            
            dayOfWeekLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(toolbar)
                make.width.equalTo(labelWidth)
                make.height.equalTo(labelWidth / 3)
                
                if index == 0 {
                    make.leading.equalTo(self.view)
                    dayOfWeekLabel.textColor = UIColor.grayColor()
                } else if index == 6 {
                    make.trailing.equalTo(self.view)
                    dayOfWeekLabel.textColor = UIColor.grayColor()
                } else {
                    make.left.equalTo(dayOfWeekLabels[index-1].snp_right)
                }
            }
        }
    }
    
    func getDayOfWeekString(index: Int) -> String {
        switch index {
        case 0:
            return "일"
        case 1:
            return "월"
        case 2:
            return "화"
        case 3:
            return "수"
        case 4:
            return "목"
        case 5:
            return "금"
        case 6:
            return "토"
        default:
            return ""
        }
    }
    
    func initSwipeView() {
        swipeView = SwipeView()
        swipeView.delegate = self
        swipeView.dataSource = self
        swipeView.pagingEnabled = true
        swipeView.layer.zPosition = 3
        
        self.view.addSubview(swipeView)
        
        let screenWidth = UIScreen.mainScreen().applicationFrame.width
        let labelWidth = screenWidth / 7;
        
        swipeView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(dayOfWeekLabels[0].snp_bottom).offset(-4)
            make.leading.trailing.equalTo(self.view)
            make.height.equalTo(labelWidth)
        }

        // TODO: UI test
//        swipeView.backgroundColor = RandomColorUtil.get()
//        swipeView.backgroundColor = UIColor.clearColor()
    }
    
    func addDummys() {
        let items = [
            ("(Vision) Vision Point", "My vision is...", selectedYear, 0, 0, 0, 0),
            ("(Weekly) Weekly Point", "My weekly point 1 is", selectedYear, selectedWeekOfYear, 0, 0, 1),
            ("(Weekly) Weekly Point", "My weekly point 2 is", selectedYear, selectedWeekOfYear, 0, 0, 1),
            ("(Weekly) Weekly Point", "My weekly point 2 is", selectedYear, selectedWeekOfYear + 1, 0, 0, 1),
            ("(Daily) Daily Point", "My daily point 1 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex, 0, 2),
            ("(Daily) Daily Point", "My daily point 2 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex, 0, 2),
            ("(Daily) Daily Point", "My daily point 3 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex, 0, 2),
            ("(Daily) Daily Point", "My daily point 4 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex, 0, 2),
            ("(Daily) Daily Point", "My daily point 1 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex - 1, 0, 2),
            ("(Daily) Daily Point", "My daily point 2 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex - 1, 0, 2),
            ("(Daily) Daily Point", "My daily point 3 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex - 1, 0, 2),
            ("(Daily) Daily Point", "My daily point 4 is", selectedYear, selectedWeekOfYear, selectedWeekdayIndex - 1, 0, 2)
        ]
        
        for(itemTitle, itemNote, year, weekOfYear, weekDay, priority, type) in items {
            TodoPoint.createInManagedObjectContext(managedObjectContext, title: itemTitle, note: itemNote, year: year, weekOfYear: weekOfYear, weekDay: weekDay, priority: priority, type:type)
        }
    }
    
    func initSelectedDayLabel() {
        selectedDayLabel = UILabel()
        self.view.addSubview(selectedDayLabel)
        selectedDayLabel.layer.zPosition = 4
        selectedDayLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(swipeView.snp_bottom)
            make.leading.trailing.equalTo(self.view)
        }
        
        // toolbar 아래쪽을 selectedDayLabel 아래쪽과 맞춤(높이 조정)
        toolbar.snp_makeConstraints { (make) -> Void in
            make.bottom.equalTo(selectedDayLabel.snp_bottom).offset(12)
        }
        
        selectedDayLabel.font = UIFont.systemFontOfSize(16)
        selectedDayLabel.textAlignment = .Center
        updateSelectedDayLabel()
        
        // UI Test
//        selectedDayLabel.backgroundColor = RandomColorUtil.get()
    }
    
    func updateSelectedDayLabel() {
        let selectedDate = CalendarUtils.getDateFromComponents(selectedYear, weekOfYear: selectedWeekOfYear, weekday: selectedWeekdayIndex + 1)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale.autoupdatingCurrentLocale()
        dateFormatter.dateStyle = .FullStyle
        dateFormatter.timeStyle = .NoStyle
        
        let weekdayFormatter = NSDateFormatter()
        weekdayFormatter.dateFormat = "EEEE"

        selectedDayLabel.text = dateFormatter.stringFromDate(selectedDate)
        
        // 타이틀도 이번 달로 변경해주자
        let monthFormatter = NSDateFormatter()
        monthFormatter.dateFormat = "MMMM"
        self.title = monthFormatter.stringFromDate(selectedDate)
        
        // 백 버튼에 년도 추가, 더 상위 컨트롤러를 만들어서 백 버튼으로 넣을 수 있게 구현 필요
        // 기획 변경: 삭제
//        let yearFormatter = NSDateFormatter()
//        yearFormatter.dateFormat = "yyyy"
//        self.navigationItem.leftBarButtonItem?.title = yearFormatter.stringFromDate(selectedDate)
    }
    
    func initTableView() {
        tableView = UITableView()
        self.view.addSubview(tableView)
        tableView.layer.zPosition = 1
        tableView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(toolbar.snp_bottom).offset(1)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo((self.bottomLayoutGuide as AnyObject as! UIView).snp_top)
        }
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        tableView.registerClass(TodoPointCell.classForCoder(), forCellReuseIdentifier: "TodoPoint")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func fetchAllTodoPoint() {
        fetchVisionTodoPoint()
        fetchWeeklyTodoPoint()
        fetchDailyTodoPoint()
    }
    
    func fetchVisionTodoPoint() {
        let fetchRequest = NSFetchRequest(entityName: "TodoPoint")
        
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let predicate = NSPredicate(format: "type == %i", 0)
        fetchRequest.predicate = predicate
        
        do {
            if let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [TodoPoint] {
                visionTodoPoints = fetchResults
            }
        } catch {
            print(error)
        }
    }
    
    func fetchWeeklyTodoPoint() {
        let fetchRequest = NSFetchRequest(entityName: "TodoPoint")
        
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let predicate1 = NSPredicate(format: "type == %i", 1)
        let predicate2 = NSPredicate(format: "year == %i", selectedYear)
        let predicate3 = NSPredicate(format: "weekOfYear == %i", selectedWeekOfYear)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate1, predicate2, predicate3])
        
        fetchRequest.predicate = predicate
        
        do {
            if let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [TodoPoint] {
                weeklyTodoPoints = fetchResults
            }
        } catch {
            print(error)
        }
    }
    
    func fetchDailyTodoPoint() {
        let fetchRequest = NSFetchRequest(entityName: "TodoPoint")
        
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let predicate1 = NSPredicate(format: "type == %i", 2)
        let predicate2 = NSPredicate(format: "year == %i", selectedYear)
        let predicate3 = NSPredicate(format: "weekOfYear == %i", selectedWeekOfYear)
        let predicate4 = NSPredicate(format: "weekDay == %i", selectedWeekdayIndex)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [predicate1, predicate2, predicate3, predicate4])
        
        fetchRequest.predicate = predicate
        
        do {
            if let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as? [TodoPoint] {
                dailyTodoPoints = fetchResults
            }
        } catch {
            print(error)
        }
    }
    
    // MARK: - SwipeView delegate

    func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView!) {
        // 스와이프 방향 체크
        if swipeView.currentItemIndex == (previousSwipeViewIndex + 1) % 3 {
            // 왼쪽 스와이프, weekOfYear 증가
            if selectedWeekOfYear == CalendarUtils.getNumberOfWeeksOfYear(selectedYear) {
                selectedYear = selectedYear + 1
                selectedWeekOfYear = 1
            } else {
                selectedWeekOfYear = selectedWeekOfYear + 1
            }
        } else if swipeView.currentItemIndex == (previousSwipeViewIndex - 1 + 3) % 3 {
            // 오른쪽 스와이프, weekOfYear 감소
            if selectedWeekOfYear == 1 {
                selectedYear = selectedYear - 1
                selectedWeekOfYear = CalendarUtils.getNumberOfWeeksOfYear(selectedWeekOfYear)
            } else {
                selectedWeekOfYear = selectedWeekOfYear - 1
            }
        }
        previousSwipeViewIndex = swipeView.currentItemIndex
        updateSelectedDayLabel()
        
        // 여기서 UI변경
        
        
        fetchAllTodoPoint()
        
        tableView.reloadData()
    }
    
    // MARK: - SwipeView data source
    func numberOfItemsInSwipeView(swipeView: SwipeView!) -> Int {
        return 3
    }
    
    func swipeView(swipeView: SwipeView!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        // TODO: 원래는 뷰를 재사용해야 하기 때문에 nil이 아닐 경우에 대입만 따로 해 주는 로직을 구현할 필요가 있음
//        if view == nil {
            let dateComponents: (year: Int, weekOfYear: Int) = caculateDateComponents(index)
            
            let rootView = UIView(frame: swipeView.bounds)
            let screenWidth = UIScreen.mainScreen().applicationFrame.width
            let labelWidth = screenWidth / 7;
            
            // 디바이스 width를 7로 나누어서 일~토 까지 width를 설정해주고, horizontal로 붙인다.
            var dayViews = [UIView]();
            var dayLabels = [UILabel]();
            
            for weekDayIndex in 0...6 {
                let dayView = UIView()
                rootView.addSubview(dayView)
                dayViews.append(dayView)
                
                dayView.snp_makeConstraints { (make) -> Void in
                    make.top.bottom.equalTo(rootView)
                    make.width.equalTo(labelWidth)
                    
                    if weekDayIndex == 0 {
                        make.leading.equalTo(rootView)
                    } else if weekDayIndex == 6 {
                        make.trailing.equalTo(rootView)
                    } else {
                        make.left.equalTo(dayViews[weekDayIndex-1].snp_right)
                    }
                }
                
                let dayLabel = UILabel()
                dayLabel.numberOfLines = 1
                dayLabel.textAlignment = .Center;
                dayLabel.text = String(CalendarUtils.getDayFromComponents(dateComponents.year, weekOfYear:
                    dateComponents.weekOfYear, weekday: weekDayIndex + 1))
                dayLabel.font = UIFont.systemFontOfSize(20, weight: 0.1) // 보통보다 조금 더 굵게 표시
                dayLabel.tag = weekDayIndex
                
                dayView.addSubview(dayLabel)
                dayLabels.append(dayLabel)
                
                let isDayLabelToday = CalendarUtils.isDateComponentEqualToday(dateComponents.year, weekOfYear:
                    dateComponents.weekOfYear, weekday: weekDayIndex + 1)
                
                dayLabel.snp_makeConstraints { (make) -> Void in
                    make.edges.equalTo(dayView).inset(UIEdgeInsetsMake(DAY_LABEL_INSET, DAY_LABEL_INSET,
                        DAY_LABEL_INSET, DAY_LABEL_INSET))
                    
                    if weekDayIndex == 0 {
                        dayLabel.textColor = UIColor.grayColor()
                    } else if weekDayIndex == 6 {
                        dayLabel.textColor = UIColor.grayColor()
                    } else {
                        dayLabel.textColor = UIColor.blackColor()
                    }
                    
                    if isDayLabelToday == true {
                        dayLabel.textColor = UIColor.redColor()
                    }
                }
                
                // TODO: circle test
                if weekDayIndex == selectedWeekdayIndex {
                    dayLabel.layer.masksToBounds = true
                    dayLabel.layer.cornerRadius = (labelWidth - (DAY_LABEL_INSET * 2)) / 2
                    dayLabel.layer.borderWidth = 7.0;
                    dayLabel.layer.borderColor = UIColor.clearColor().CGColor
                    if isDayLabelToday == true {
                        dayLabel.backgroundColor = UIColor.redColor()
                    } else {
                        dayLabel.backgroundColor = UIColor.blackColor()
                    }
                    dayLabel.textColor = UIColor.whiteColor()
                }
                
                // recognizer는 한 뷰에만 적용 가능해서 동적으로 생성
                let tapRecognizer = UITapGestureRecognizer(target: self, action: "dayLabelTouchBegan:")
                dayLabel.userInteractionEnabled = true
                dayLabel.addGestureRecognizer(tapRecognizer)
                
                // TODO: UI test
//                dayView.backgroundColor = RandomColorUtil.get()
//                dayLabel.backgroundColor = RandomColorUtil.get()
            }
            return rootView
//        } else {
//            NSLog("index: %d", index)
//            return view
//        }
    }
    
    func caculateDateComponents(index: Int) -> (year: Int, weekOfYear: Int) {
        // 초기화시는 그대로 사용
        var year: Int = selectedYear
        var weekOfYear: Int = selectedWeekOfYear
        
        // 왼/오른 스와이프 체크
        if index == (swipeView.currentItemIndex + 1) % 3 {
            // 왼쪽 스와이프, weekOfYear 증가
            if selectedWeekOfYear == CalendarUtils.getNumberOfWeeksOfYear(selectedYear) {
                year = selectedYear + 1
                weekOfYear = 1
            } else {
                year = selectedYear
                weekOfYear = selectedWeekOfYear + 1
            }
        } else if index == (swipeView.currentItemIndex - 1 + 3) % 3 {
            // 오른쪽 스와이프, weekOfYear 감소
            if selectedWeekOfYear == 1 {
                year = selectedYear - 1
                weekOfYear = CalendarUtils.getNumberOfWeeksOfYear(year)
            } else {
                year = selectedYear
                weekOfYear = selectedWeekOfYear - 1
            }
        }
        return (year, weekOfYear)
    }
    
    func dayLabelTouchBegan(recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            let dayLabel: UILabel = recognizer.view as! UILabel
            selectedWeekdayIndex = dayLabel.tag
            updateSelectedDayLabel()
            swipeView.reloadData()
            
            fetchAllTodoPoint()
            
            tableView.reloadData()
        }
    }
    
    // MARK: - TableView delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Get the LogItem for this index
        var todoPointItem : TodoPoint
        
        if indexPath.section == 0 {
            todoPointItem = visionTodoPoints[indexPath.row]
        } else if indexPath.section == 1 {
            todoPointItem = weeklyTodoPoints[indexPath.row]
        } else  {
            todoPointItem = dailyTodoPoints[indexPath.row]
        }
        
        let titlePrompt = UIAlertController(title: "Note", message: todoPointItem.note, preferredStyle: .Alert)
        titlePrompt.addAction(UIAlertAction(title: "Ok", style: .Default,
            handler: nil))
        
        self.presentViewController(titlePrompt, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Visionin"
        } else if section == 1 {
            return "Weekly"
        } else {
            return "Daily"
        }
    }
    
    // MARK: - TableView data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return visionTodoPoints.count
        } else if section == 1 {
            return weeklyTodoPoints.count
        } else {
            return dailyTodoPoints.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodoPoint") as! TodoPointCell
        
        
        // Get the LogItem for this index
        var todoPointItem : TodoPoint
        
        if indexPath.section == 0 {
            todoPointItem = visionTodoPoints[indexPath.row]
        } else if indexPath.section == 1 {
            todoPointItem = weeklyTodoPoints[indexPath.row]
        } else  {
            todoPointItem = dailyTodoPoints[indexPath.row]
        }
        
        // Set the title of the cell to be the title of the logItem
        cell.textLabel?.text = todoPointItem.title
        cell.textLabel?.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        cell.state = todoPointItem.state!
        cell.detailTextLabel?.text = todoPointItem.note
        cell.currentSection = indexPath.section
        cell.currentRow = indexPath.row
        
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if(editingStyle == .Delete) {
            
            var itemToDelete : TodoPoint
            
            if indexPath.section == 0 {
                itemToDelete = visionTodoPoints[indexPath.row]
                managedObjectContext.deleteObject(itemToDelete)
                fetchVisionTodoPoint()
            } else if indexPath.section == 1 {
                itemToDelete = weeklyTodoPoints[indexPath.row]
                managedObjectContext.deleteObject(itemToDelete)
                fetchWeeklyTodoPoint()
            } else  {
                itemToDelete = dailyTodoPoints[indexPath.row]
                managedObjectContext.deleteObject(itemToDelete)
                fetchDailyTodoPoint()
            }
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            save()
        }
    }
    
    func save() {
        do {
            try managedObjectContext.save()
        } catch{
            print(error)
        }
    }
    
    // MARK: - ViewController Cycle
    
    override func viewWillAppear(animated: Bool) {
//        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
        
        print("View Will Appear")
        naviHairlineImageView?.hidden = true
        
        fetchAllTodoPoint()
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // 여기서 처리를 안 해주면 깨짐. UI가 다 뜨고 나서 진행해야 하는 듯
        swipeView.wrapEnabled = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        naviHairlineImageView?.hidden = false
    }
    
    // MARK:

    func insertNewTodoPoint(sender: AnyObject) {
        
        let viewControllerForPopover = UIStoryboard(name: "AddTodoPoint", bundle: nil).instantiateViewControllerWithIdentifier("addTodoPointViewController")
        self.navigationController?.pushViewController(viewControllerForPopover, animated: true)
        
        /*
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
             
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        newManagedObject.setValue(NSDate(), forKey: "timeStamp")
             
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        */
    }

    // MARK: - Segues

    /*
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    */

    // MARK: - Toolbar
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .Top
    }
    
    // MARK: - Table View

    /*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath))
                
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //print("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }

    */
    
//    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
//        let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
//        cell.textLabel!.text = object.valueForKey("timeStamp")!.description
//    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Event", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //print("Unresolved error \(error), \(error.userInfo)")
             abort()
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    /*
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    */

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */
    
    func doneStateChange(state: NSNumber, section: Int, row: Int) {
        if section == 0 {
            visionTodoPoints[row].changeState(state)
        } else if section == 1 {
            weeklyTodoPoints[row].changeState(state)
        } else {
            dailyTodoPoints[row].changeState(state)
        }
        
        save()
    }

}

