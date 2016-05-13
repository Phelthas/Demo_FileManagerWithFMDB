//
//  ViewController.m
//  Demo_fmdb
//
//  Created by luxiaoming on 16/5/11.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import "ViewController.h"
#import "Demo_DBManager.h"
#import "DemoFileListViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>


@property (weak, nonatomic) IBOutlet UITableView *talbeView;

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupUI];
    
    
    [self loadSavedData];
    [[Demo_DBManager sharedDBManager] logAllDBFile];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupUI {
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"AllFile" style:UIBarButtonItemStylePlain target:self action:@selector(hadnleLeftItemTapped:)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"AddUser" style:UIBarButtonItemStylePlain target:self action:@selector(handleRightItemTapped:)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)loadSavedData {
    [[Demo_DBManager sharedDBManager] fetchAllUserWithCompletion:^(NSArray *resultArray, NSError *error) {
        self.dataArray = resultArray;
        [self.talbeView reloadData];
    }];
}

#pragma mark - Action

- (void)hadnleLeftItemTapped:(UIBarButtonItem *)sender {
    DemoFileListViewController *fileListViewController = [[DemoFileListViewController alloc] init];
    [self.navigationController pushViewController:fileListViewController animated:YES];
}

- (void)handleRightItemTapped:(UIBarButtonItem *)sender {
    Demo_User *newUser = [[Demo_User alloc] init];
    NSInteger randomId = arc4random() % 5 + 3;
    newUser.userId = randomId;
    newUser.name = [NSString stringWithFormat:@"userName_%@", @(randomId)];
    newUser.fileArray = @[@(randomId), @(randomId + 1), @(randomId + 2)];
    
    [[Demo_DBManager sharedDBManager] saveUserToDB:newUser];
    [self loadSavedData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    Demo_User *user = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = user.name;
    NSArray *tempArray = [user.fileArray valueForKey:@"stringValue"];
    cell.detailTextLabel.text = [tempArray componentsJoinedByString:@","];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Demo_User *user = [self.dataArray objectAtIndex:indexPath.row];
        [[Demo_DBManager sharedDBManager] deleteUserFromDBWithUserId:user.userId completion:^{
            [self loadSavedData];
        }];
    }
}

@end
