package com.example.gryphon.calculator

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast

import com.example.gryphon.calculator.R

class MainActivity: AppCompatActivity() {

    var calculator: Calculator = Calculator()
    var display: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        print(com.example.gryphon.calculator.R.id.textView)
        display = findViewById(com.example.gryphon.calculator.R.id.textView)
    }

    fun tap(view: View) {

        val button = view as Button
        val label = button.text.toString()
        if (label != null) {
            try {
                calculator.input(label)
                display?.text = calculator.displayValue
            }
            catch (e: CalculatorError) {
                Toast.makeText(this, "Exception: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
}