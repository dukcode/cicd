package com.dukcode.cicd.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

	@Value("${my-secret}")
	private String mySecret;

	@GetMapping("/hello")
	public String hello() {
		return mySecret;
	}
}
