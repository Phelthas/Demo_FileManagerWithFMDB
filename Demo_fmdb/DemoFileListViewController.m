//
//  DemoViewController.m
//  Demo_fmdb
//
//  Created by luxiaoming on 16/5/12.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import "DemoFileListViewController.h"
#import "Demo_DBManager.h"

@interface DemoFileListViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *talbeView;

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation DemoFileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[Demo_DBManager sharedDBManager] fetchAllFileWithCompletion:^(NSArray *resultArray, NSError *error) {
        self.dataArray = resultArray;
        [self.talbeView reloadData];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    Demo_File *file = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = file.name;
    return cell;
}



@end
