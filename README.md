CTView
======

A UIView that supports URL link and emoji images.
Usage:
        CTView *view = [[CTView alloc] initWithFrame:CGRectMake(0, 5, 320, 50)];
        view.delegate = self;
        view.text = @“A CTView Test. [cry][cry][cry][cry][cry][cry][cry]";
        view.font = [UIFont systemFontOfSize:15];