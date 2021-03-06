//
//  TextView.swift
//  Noted
//
//  Created by Robert Taylor on 16/07/2020.
//  Copyright © 2020 Myware. All rights reserved.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.isScrollEnabled = true
        view.isEditable = true
        view.isSelectable = true
        view.isUserInteractionEnabled = true
        view.showsVerticalScrollIndicator = false
        view.font = UIFont.systemFont(ofSize: 15.0)
        view.spellCheckingType = UITextSpellCheckingType.no
        view.autocorrectionType = UITextAutocorrectionType.no
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let selectedRange = uiView.selectedTextRange {
            uiView.text = text
            uiView.selectedTextRange = uiView.textRange(from: selectedRange.start, to: selectedRange.start)
            uiView.scrollRangeToVisible(uiView.selectedRange)
            return
        }
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var control: TextView
        
        init(_ control: TextView) {
            self.control = control
        }
        
        func textViewDidChange(_ textView: UITextView) {
            control.text = textView.text
        }
    }
}

