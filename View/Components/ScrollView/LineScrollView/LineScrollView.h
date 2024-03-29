#import <UIKit/UIKit.h>


@class LineScrollView;
@class LineScrollViewCell;


/*
 Usage i.e:
 
 LineScrollView* lineScrollView = [[LineScrollView alloc] init];
 [lineScrollView registerCellClass: [ImageLabelLineScrollCell class]]; // ImageLabelLineScrollCell is LineScrollViewCell's subClass
 lineScrollView.dataSource = self;
 [self.view addSubview: lineScrollView];
 
 
 lineScrollView.backgroundColor = [UIColor grayColor];
 lineScrollView.eachCellWidth = 50;
 lineScrollView.currentIndex = 7;
 lineScrollView.frame = CGRectMake(0, 100, 320, 80);
 
 */


@protocol LineScrollViewDataSource <NSObject>


@optional

-(BOOL)lineScrollView:(LineScrollView *)lineScrollView shouldShowIndex:(int)index;
-(void)lineScrollView:(LineScrollView *)lineScrollView willShowIndex:(int)index isReload:(BOOL)isReload;
-(void)lineScrollView:(LineScrollView *)lineScrollView touchBeganAtPoint:(CGPoint)point;
-(void)lineScrollView:(LineScrollView *)lineScrollView touchEndedAtPoint:(CGPoint)point;


@end



@interface LineScrollView : UIScrollView


@property (assign) CGFloat eachCellWidth;   // should be CGFloat ! important !!! cause will raise the caculate problem

@property (assign, nonatomic) int currentIndex;


@property (strong, readonly) UIView* contentView;

// Yes : is heading right, currentIndex is decrease, contentOffset.x is decrease
@property (assign, readonly) BOOL currentDirection;


@property (assign) id<LineScrollViewDataSource> dataSource;


@property (copy) BOOL(^lineScrollViewShouldShowIndex)(LineScrollView *lineScrollView, int index);
@property (copy) void(^lineScrollViewWillShowIndex)(LineScrollView *lineScrollView, int index, BOOL isReload);
@property (copy) void(^lineScrollViewTouchBeganAtPoint)(LineScrollView *lineScrollView, CGPoint point);
@property (copy) void(^lineScrollViewTouchEndedAtPoint)(LineScrollView *lineScrollView, CGPoint point);





#pragma mark - Public Methods

-(void) reloadCells;

-(void) registerCellClass:(Class)cellClass;

-(LineScrollViewCell*) visibleCellAtIndex: (int)index;

-(int) indexOfVisibleCell: (LineScrollViewCell*)cell;


@end
