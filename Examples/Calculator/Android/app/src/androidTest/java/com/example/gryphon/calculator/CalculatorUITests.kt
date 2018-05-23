package com.example.gryphon.calculator

import android.support.test.espresso.Espresso.onView
import android.support.test.espresso.action.ViewActions.click
import android.support.test.espresso.assertion.ViewAssertions.matches
import android.support.test.espresso.matcher.ViewMatchers.withId
import android.support.test.espresso.matcher.ViewMatchers.withText
import android.support.test.rule.ActivityTestRule
import android.support.test.runner.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CalculatorUITests {

    @Rule
    @JvmField
    val activity = ActivityTestRule<MainActivity>(MainActivity::class.java)

    @Test
    fun testAddition() {
        onView(withId(R.id.button6)).perform(click())
        onView(withId(R.id.buttonPlu)).perform(click())
        onView(withId(R.id.button2)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())

        onView(withId(R.id.textView))
                .check(matches(withText("8.0")))

        onView(withId(R.id.buttonPlu)).perform(click())
        onView(withId(R.id.button2)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())

        onView(withId(R.id.textView))
                .check(matches(withText("10.0")))
    }

    @Test
    fun testSubtraction() {
        onView(withId(R.id.button6)).perform(click())
        onView(withId(R.id.buttonMin)).perform(click())
        onView(withId(R.id.button2)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())

        onView(withId(R.id.textView))
                .check(matches(withText("4.0")))
    }

    @Test
    fun testDivision() {
        onView(withId(R.id.button2)).perform(click())
        onView(withId(R.id.button5)).perform(click())
        onView(withId(R.id.buttonDiv)).perform(click())
        onView(withId(R.id.button4)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())

        onView(withId(R.id.textView))
                .check(matches(withText("6.25")))
    }

    @Test
    fun testMultiplication() {
        onView(withId(R.id.button1)).perform(click())
        onView(withId(R.id.button9)).perform(click())
        onView(withId(R.id.buttonMul)).perform(click())
        onView(withId(R.id.button8)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())

        onView(withId(R.id.textView))
                .check(matches(withText("152.0")))
    }

    @Test
    fun testDelete() {
        onView(withId(R.id.button1)).perform(click())
        onView(withId(R.id.button9)).perform(click())
        onView(withId(R.id.button8)).perform(click())
        onView(withId(R.id.button7)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("1987")))

        onView(withId(R.id.buttonD)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("198")))

        onView(withId(R.id.buttonD)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("19")))

        onView(withId(R.id.buttonD)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("1")))

        onView(withId(R.id.buttonD)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("0")))
    }

    @Test
    fun testClear() {
        onView(withId(R.id.button2)).perform(click())
        onView(withId(R.id.button5)).perform(click())
        onView(withId(R.id.buttonDiv)).perform(click())
        onView(withId(R.id.button4)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())
        onView(withId(R.id.buttonCle)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("0")))

        onView(withId(R.id.button5)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("5")))

        onView(withId(R.id.button1)).perform(click())
        onView(withId(R.id.button9)).perform(click())
        onView(withId(R.id.buttonMul)).perform(click())
        onView(withId(R.id.button8)).perform(click())
        onView(withId(R.id.buttonCle)).perform(click())
        onView(withId(R.id.buttonCle)).perform(click())
        onView(withId(R.id.buttonPlu)).perform(click())
        onView(withId(R.id.button2)).perform(click())
        onView(withId(R.id.buttonEqu)).perform(click())
        onView(withId(R.id.textView))
                .check(matches(withText("2.0")))
    }
}