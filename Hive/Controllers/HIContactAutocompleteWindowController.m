//
//  HIContactAutocompleteWindowController.m
//  Hive
//
//  Created by Jakub Suder on 20.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIAddress.h"
#import "HIContact.h"
#import "HIContactAutocompleteCellView.h"
#import "HIContactAutocompleteWindowController.h"

static const CGFloat MaxAutocompleteHeight = 300.0;


@implementation HIContactAutocompleteWindowController

- (id)init
{
    return [super initWithWindowNibName:@"HIContactAutocompleteWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self.arrayController setManagedObjectContext: DBM];
    [self.arrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:NULL];
}

- (void)dealloc
{
    [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects"];
}


#pragma mark - Filtering

- (void)searchWithQuery:(NSString *)query
{
    if (query.length > 0)
    {
        self.arrayController.filterPredicate = [self filterPredicateForQuery:query];
    }
    else
    {
        self.arrayController.filterPredicate = nil;
    }
}

- (void)searchWithContact:(HIContact *)contact
{
    self.arrayController.filterPredicate = [NSPredicate predicateWithFormat:@"contact = %@", contact];
}

- (NSPredicate *)filterPredicateForQuery:(NSString *)query
{
    NSArray *tokens = [query componentsSeparatedByString:@" "];

    NSMutableArray *predicateParts = [[NSMutableArray alloc] init];
    NSMutableArray *params = [[NSMutableArray alloc] init];

    NSString *predicatePartForToken =
    @"(address CONTAINS[cd] %@ || "
    @"caption CONTAINS[cd] %@ || "
    @"contact.firstname CONTAINS[cd] %@ || "
    @"contact.lastname CONTAINS[cd] %@)";

    for (NSString *token in tokens)
    {
        if (token.length == 0) continue;

        [predicateParts addObject:predicatePartForToken];
        [params addObjectsFromArray:@[token, token, token, token]];
    }

    NSString *completePredicate = [predicateParts componentsJoinedByString:@" && "];
    return [NSPredicate predicateWithFormat:completePredicate argumentArray:params];
}


#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)table viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    HIContactAutocompleteCellView *cell = [table makeViewWithIdentifier:column.identifier owner:self];
    HIAddress *address = self.arrayController.arrangedObjects[row];

    cell.textField.stringValue = address.contact.name;
    cell.addressLabel.stringValue = address.addressSuffixWithCaption;
    cell.imageView.image = address.contact.avatarImage;

    return cell;
}


#pragma mark - Reacting to keyboard events

- (void)moveSelectionUp
{
    if (self.tableView.numberOfRows > 0)
    {
        NSInteger row = self.tableView.selectedRow;
        NSInteger newRow = (row >= 0) ? (row - 1 + self.tableView.numberOfRows) % self.tableView.numberOfRows : 0;

        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    }
}

- (void)moveSelectionDown
{
    if (self.tableView.numberOfRows > 0)
    {
        NSInteger row = self.tableView.selectedRow;
        NSInteger newRow = (row >= 0) ? (row + 1) % self.tableView.numberOfRows : 0;

        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    }
}

- (void)confirmSelection
{
    NSInteger row = self.tableView.selectedRow;

    if (row >= 0)
    {
        HIAddress *address = self.arrayController.arrangedObjects[self.tableView.selectedRow];
        [self.delegate addressSelectedInAutocomplete:address];
        [self.tableView deselectAll:self];
    }
}


#pragma mark - Updating size

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.arrayController)
    {
        [self resizeWindowToContentHeight];
    }
}

- (void)resizeWindowToContentHeight
{
    if (self.tableView.numberOfRows > 0)
    {
        CGFloat targetHeight = self.tableView.numberOfRows * self.tableView.rowHeight;
        targetHeight = MIN(MaxAutocompleteHeight, targetHeight);

        NSRect windowFrame = self.window.frame;
        CGFloat diff = targetHeight - windowFrame.size.height;
        windowFrame.size.height += diff;
        windowFrame.origin.y -= diff;

        [self.window setFrame:windowFrame display:YES];
        [self.window setIsVisible:YES];
    }
    else
    {
        [self.window setIsVisible:NO];
    }
}

@end
