//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//
internal fun definition1() {
}

internal fun definition2() {
	var x: Int = 0
}

internal fun definition3(x: Int, y: Int) {
}

internal fun definition4(): Int {
	return 0
}

internal fun foo() {
}

internal fun foo1(bar: Int) {
}

internal fun foo2(bar: Int) {
}

internal fun foo3(bar: Int, baz: Int) {
}

internal fun foo4(bar: Int, baz: Int) {
}

internal fun foo6(bar: Int, baz: Int) {
}

internal fun bla(): Int {
	return 0
}

internal fun bla1(bar: Int): Int {
	return 1
}

internal fun bla2(bar: Int): Int {
	return 2
}

internal fun bla3(bar: Int, baz: Int): Int {
	return 3
}

internal fun bla4(bar: Int, baz: Int): Int {
	return 4
}

internal fun bla6(bar: Int, baz: Int): Int {
	return 6
}

internal fun bar1(a: Int = 1) {
}

internal fun bar2(a: Int = 1, b: Int = 2) {
}

internal fun bar3(a: Int = 1, b: Int) {
}

internal fun bar4(a: Int, b: Int = 2) {
}

internal fun f(a: Int = 0, b: Int = 0, c: Int = 0) {
	println("${a} ${b} ${c}")
}

fun variadics(a: Int, vararg b: Int, c: Int = 0) {
	print(a)
	for (element in b) {
		print(element)
	}
	println(c)
}

internal open class AClassWithABigName {
}

internal fun fooBarBaz(
	someBigName: AClassWithABigName,
	anotherBigName: AClassWithABigName,
	yetAnEvenBiggerName: AClassWithABigName,
	aSmallerName: AClassWithABigName)
{
}

internal fun fooFooBarBaz(
	someBigName: AClassWithABigName,
	anotherBigName: AClassWithABigName,
	yetAnEvenBiggerName: AClassWithABigName,
	aSmallerName: AClassWithABigName)
	: AClassWithABigName
{
	return AClassWithABigName()
}

internal fun fooFooBarBazFoo(
	someBigName: AClassWithABigName,
	anotherBigName: AClassWithABigName,
	yetAnEvenBiggerName: AClassWithABigName,
	aParameterWithADefaultValue: Int = 0,
	aSmallerName: AClassWithABigName)
	: AClassWithABigName
{
	return AClassWithABigName()
}

fun main(args: Array<String>) {
	foo()
	foo1(bar = 0)
	foo2(0)
	foo3(bar = 0, baz = 0)
	foo4(0, baz = 0)
	foo6(0, 0)

	println("${bla()}")
	println("${bla1(bar = 0)}")
	println("${bla2(0)}")
	println("${bla3(bar = 0, baz = 0)}")
	println("${bla4(0, baz = 0)}")
	println("${bla6(0, 0)}")

	bar1()
	bar1(a = 0)
	bar2()
	bar2(a = 0)
	bar2(b = 0)
	bar2(a = 0, b = 0)
	bar3(b = 0)
	bar3(a = 0, b = 0)
	bar4(a = 0)
	bar4(a = 0, b = 0)
	f(a = 1)
	f(b = 1)
	f(a = 1, b = 1)
	f(c = 1)
	f(a = 1, c = 1)
	f(b = 1, c = 1)
	f(a = 1, b = 1, c = 1)
	variadics(1, 1, 2, 3, c = 1)
	variadics(1, 1, 2, 3)
	fooBarBaz(
		someBigName = AClassWithABigName(),
		anotherBigName = AClassWithABigName(),
		yetAnEvenBiggerName = AClassWithABigName(),
		aSmallerName = AClassWithABigName())
	fooFooBarBaz(
		someBigName = AClassWithABigName(),
		anotherBigName = AClassWithABigName(),
		yetAnEvenBiggerName = AClassWithABigName(),
		aSmallerName = AClassWithABigName())
	fooFooBarBazFoo(
		someBigName = AClassWithABigName(),
		anotherBigName = AClassWithABigName(),
		yetAnEvenBiggerName = AClassWithABigName(),
		aSmallerName = AClassWithABigName())
	fooFooBarBazFoo(
		someBigName = AClassWithABigName(),
		anotherBigName = AClassWithABigName(),
		yetAnEvenBiggerName = AClassWithABigName(),
		aParameterWithADefaultValue = 1,
		aSmallerName = AClassWithABigName())
}
